# ADR-04: Notification Scheduling and Delivery

## Status

Accepted

## Context

Daily Logos needs to deliver daily quotes through user-selected channels on selected weekdays and at a selected local hour. A user can have different notification settings for each channel.

The application already uses Phoenix, Ecto, PostgreSQL, and Swoosh. Notification scheduling and delivery must survive application restarts, support retries, and scale without introducing a recurring process or recurring job for every user.

This decision covers backend scheduling and delivery architecture. Settings UI, channel connection flows, and provider selection are outside its scope.

## Options Considered

### Option A: Per-Subscription Scheduled Job

Create a future Oban job for each subscription. Each execution schedules the next occurrence.

- Supports independent schedules without a shared lookup.
- Requires coordination when subscriptions change or jobs are cancelled.
- Requires reconciliation to detect subscriptions left without a future job.
- Risks coupling future scheduling to the success of the previous delivery.

### Option B: Shared Hourly Dispatcher and Persistent Subscriptions (Chosen)

Run one recurring dispatcher that finds due subscriptions and creates independent delivery jobs.

- Centralizes recurrence and recovery logic.
- Keeps scheduling independent of provider failures.
- Supports shared whole-hour slots without maintaining a recurring job per user.
- Requires indexed subscription queries, batching, and persistent dispatch progress.

### Option C: PubSub or an External Message Broker

Publish time-slot events to subscribers through Phoenix.PubSub or an external broker.

- Phoenix.PubSub alone does not provide durable delivery, replay, or persistent subscriptions.
- An external broker adds infrastructure without removing the need for persistent calendar and delivery state.
- Oban already provides the persistent queue required for this workload.

## Decision

Choose **Option B**: persistent subscriptions, one shared hourly Oban dispatcher, and independent delivery jobs in channel-specific Oban queues backed by PostgreSQL.

Do not introduce Phoenix.PubSub or an external message broker for scheduled notification delivery.

## Decision Details

### 1. Subscription Model

Store subscriptions in `notification_subscriptions`, with one subscription per user and channel, enforced by a unique constraint on `(user_id, channel)`.

Each subscription contains:

- `user_id`
- `channel`
- `weekdays`, using ISO weekday numbers from 1 (Monday) to 7 (Sunday)
- `local_hour`, restricted to whole hours from 0 to 23
- `timezone`, an IANA identifier such as `Europe/Rome`
- `enabled`
- Persisted notification locale, validated against the application's configured locales

Whole-hour slots are allowed values, not separate schedule records or processes. Channel destinations and credentials belong to the channel integration, rather than the calendar definition.

### 2. Local Calendar Semantics

Local hour, weekdays, and IANA timezone are the source of truth. Do not replace them with a permanently converted UTC hour or a fixed UTC offset.

Calculate UTC occurrences for specific dates using a maintained timezone database compatible with Elixir, such as `tzdata`. This preserves the selected local hour across daylight saving changes and handles UTC/local date boundaries.

Initially, support only timezones whose offsets remain aligned with whole UTC hours over the supported scheduling horizon. Validate this against timezone data, not only the offset on the date the subscription is created.

To support fractional-offset timezones precisely, increase the frequency of the same dispatcher; the subscription and delivery architecture does not need to change.

The policy for nonexistent and repeated local hours during daylight saving transitions must be defined and tested before implementation is released.

### 3. Hourly Dispatcher

Use Oban's Cron plugin to enqueue one shared recurring dispatcher at the start of each UTC hour. This is one logical recurring task, not one task per user, timezone, or channel.

The dispatcher:

1. Reads persistent dispatch progress and determines the interval to process.
2. Resolves local calendar slots within that interval for the timezones used by active subscriptions.
3. Finds matching enabled subscriptions by local weekday, hour, and timezone.
4. Creates deliveries and their Oban jobs in bounded batches.
5. Records progress only after the corresponding work is durably committed.

Use indexed queries and bounded batches rather than loading all subscribers into memory. Coordinate concurrent dispatcher executions through database-backed locking or equivalent serialization.

Do not rely on the dispatcher starting at the exact scheduled second, or on Cron replaying ticks missed during downtime. Run the same recovery path after application startup as well as on hourly ticks.

### 4. Delivery Records and Atomic Enqueueing

Store individual occurrences in `notification_deliveries`, including:

- Subscription reference
- `scheduled_for`, the intended UTC instant
- Local occurrence date
- Selected quote reference and notification locale
- Delivery status and relevant provider outcome metadata

Enforce uniqueness on `(subscription_id, scheduled_for)` to prevent repeated dispatch attempts from generating the same occurrence twice.

Create each delivery and its Oban job in the same database transaction. Jobs receive a `delivery_id`, rather than credentials or the entire subscription.

If dispatch progress is committed per batch, it must identify the last durably processed batch. Otherwise, advance the interval checkpoint only after every batch is committed. A retry can revisit committed batches safely through delivery uniqueness; progress must never skip uncommitted work.

Choose the quote using the occurrence's local date, not the worker's execution date. Persist the quote reference and locale so retries do not select a different day's quote or inherit a process-default language.

### 5. Queues, Workers, and Channel Adapters

Use a ports-and-adapters (hexagonal) architecture for channel delivery. Application use cases depend on a delivery port expressed as an Elixir behaviour, implemented by provider-specific adapters. Keep scheduling and business rules independent of provider APIs, credentials, and payload formats. See [ADR-05: Notification Channel Integrations with Ports and Adapters](adr-05-notification-channel-integrations.md) for channel contracts and supported delivery modes.

Use independent Oban queues for channels, such as `notifications_email`, `notifications_telegram`, and `notifications_slack`.

Each job processes one delivery through the relevant adapter. Configure concurrency per queue so a slow provider does not consume all delivery capacity.

- Retry transient failures with bounded backoff.
- Treat permanent destination or authorization failures separately from transient errors.
- Respect provider rate limits and retry guidance across all worker instances; queue concurrency alone is not rate limiting.
- Recheck subscription eligibility before sending, so disabled or changed subscriptions do not blindly send stale pending deliveries.
- Reuse Swoosh and the existing mailer for email, keeping quote delivery separate from account authentication messages.
- Use Req for HTTP-based channel integrations.
- Keep provider credentials out of job arguments and logs.

Provider acceptance is distinct from confirmed recipient delivery. Record only states supported by provider evidence, using webhooks where available.

Delivery uniqueness prevents duplicate occurrence creation, but does not guarantee exactly-once external sending. A provider may accept a request before the worker loses its response. Use a stable delivery-based idempotency key where the provider supports it; otherwise acknowledge the residual duplicate risk.

### 6. Recovery and Observability

Persist dispatch progress so restarts do not lose unprocessed intervals. Apply a bounded recovery window rather than sending an unlimited backlog of old quotes.

The recovery window and handling of expired occurrences must be agreed before release. Recovery must also respect subscription creation and modification times rather than creating retroactive notifications for newly configured settings.

Monitor queue backlog, delivery delay relative to `scheduled_for`, retry counts, permanent failures, and dispatcher progress. Define retention and pruning for Oban jobs and delivery records before production rollout.

## Consequences

### Positive

- Uses the existing PostgreSQL infrastructure without a separate broker.
- Keeps recurring scheduling centralized and independent of individual delivery outcomes.
- Supports channel isolation, controlled concurrency, and additional worker instances.
- Preserves users' local calendar intent and provides an auditable delivery history.

### Negative / Risks

- Whole-hour dispatch initially restricts supported timezones.
- Scheduling accuracy depends on dispatcher availability and queue capacity; exact-time delivery is not guaranteed.
- Checkpointing, batch recovery, and subscription changes require careful transactional behavior.
- Daylight saving transitions and external-provider idempotency remain explicit correctness concerns.

## Verification Criteria

- Unit tests cover local weekday/date boundaries, daylight saving transitions, timezone eligibility, and quote selection for the occurrence date.
- Integration tests cover atomic delivery/job creation, uniqueness under retries and concurrent dispatchers, checkpoint recovery after partial batches, and subscription changes.
- Worker tests cover channel routing, transient and permanent failures, provider idempotency where supported, and independent retries.
- Tests use controlled time and adapter responses rather than real provider calls or sleeps.

## Open Decisions Before Release

- Maximum recovery delay and treatment of expired occurrences
- Behavior for nonexistent and repeated local hours
- Exact invalidation rules for pending deliveries after subscription edits
- Provider-specific rate limits, channel connection verification, and credential storage
- Delivery history retention period

## Alternative Revisit Triggers

- Fractional-offset timezone support requires a more frequent dispatcher.
- Users need multiple schedules per channel or minute-level scheduling.
- Measured fan-out, queue delay, or database contention exceeds the capacity of this design.
- Provider constraints require different batching or delivery infrastructure.
