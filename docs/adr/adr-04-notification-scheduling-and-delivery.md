# ADR-04: Notification Scheduling and Delivery

## Status

Accepted

## Context

Daily Logos needs to deliver daily quotes to a user's verified email address on selected weekdays and at a selected local hour. Email is the only supported notification destination.

The application already uses Phoenix, Ecto, PostgreSQL, and Swoosh. Subscriptions and enqueued jobs must survive application restarts, support short bounded retries, and scale without introducing a recurring process or recurring job for every user. Notifications are best-effort: missed slots and sends that expire or exhaust their attempts may be lost.

This decision covers backend scheduling and email delivery architecture. The Notifications UI is specified in [Notifications UI](../NOTIFICATIONS_UI.md).

## Options Considered

### Option A: Per-Subscription Scheduled Job

Create a future Oban job for each subscription. Each execution schedules the next occurrence.

- Supports independent schedules without a shared lookup.
- Requires coordination when subscriptions change or jobs are cancelled.
- Requires reconciliation to detect subscriptions left without a future job.
- Risks coupling future scheduling to the success of the previous delivery.

### Option B: Shared 15-Minute Dispatcher and Persistent Email Subscriptions (Chosen)

Run one recurring dispatcher that finds due subscriptions and creates independent delivery jobs.

- Centralizes recurrence logic without replaying missed slots.
- Keeps scheduling independent of email transport failures.
- Supports whole-hour local email schedules, including half-hour and quarter-hour UTC offsets, without maintaining a recurring job per user.
- Requires indexed subscription queries and bounded batching, but no persistent dispatch progress.

### Option C: PubSub or an External Message Broker

Publish time-slot events to subscribers through Phoenix.PubSub or an external broker.

- Phoenix.PubSub alone does not provide durable delivery, replay, or persistent subscriptions.
- An external broker adds infrastructure without removing the need for persistent subscriptions and queued jobs.
- Oban already provides the persistent queue required for this workload.

## Decision

Choose **Option B**: persistent email subscriptions, one shared Oban dispatcher running every 15 minutes, and email delivery jobs in a dedicated Oban queue backed by PostgreSQL.

Do not introduce Phoenix.PubSub or an external message broker for scheduled notification delivery.

Store the email schedule in `notification_subscriptions`; resolve the destination from the user's verified account email rather than duplicating the address. Use Oban jobs directly for delivery execution, with no separate `notification_deliveries` table or dispatcher checkpoint table. Do not recover slots missed during downtime or retry notifications beyond a short expiry window.

These simplifications replace the earlier delivery-ledger and checkpoint-recovery design. They are intentional reductions in delivery guarantees, not deferred implementation tasks.

## Decision Details

### 1. Subscription Model

Store the email schedule in `notification_subscriptions`, with one row per user. The verified account email is the destination; do not copy it into the subscription or create a separate destination table. The deployed table has a `provider` discriminator from the initial implementation; supported subscriptions use only `email`.

Allow one email subscription per user, enforced by a unique constraint or index.

Each subscription contains:

- `user_id`
- `weekdays`, using ISO weekday numbers from 1 (Monday) to 7 (Sunday)
- `local_hour`, restricted to whole hours from 0 to 23
- `timezone`, an IANA identifier such as `Europe/Rome`
- `enabled`
- Persisted notification locale, validated against the application's configured locales

Whole-hour slots are allowed values, not separate schedule records or processes. The schedule belongs to the user's verified email destination.

New subscriptions are disabled. Disabled subscriptions may have incomplete calendar settings; enabling requires at least one weekday, a valid hour, a supported timezone, a configured locale, and a verified account email.

### 2. Local Calendar Semantics

Local hour, weekdays, and IANA timezone are the source of truth. Do not replace them with a permanently converted UTC hour or a fixed UTC offset.

Calculate UTC occurrences for specific dates using a maintained timezone database compatible with Elixir, such as `tzdata`. This preserves the selected local hour across daylight saving changes and handles UTC/local date boundaries.

Support IANA timezones with whole-hour, half-hour, and quarter-hour UTC offsets. The dispatcher runs every 15 minutes so a selected whole local hour can fall on UTC minute 00, 15, 30, or 45. Users still select whole local hours only; this does not introduce minute-level schedule controls.

Validate timezone identifiers against the maintained timezone database. Do not restrict choices to whole-hour UTC offsets or introduce a 12-month whole-hour-offset eligibility scan. The timezone database is still required to convert local calendars to UTC and handle daylight saving changes.

If the selected local hour does not exist during a daylight saving transition, skip that local date. If it occurs twice, use the first UTC occurrence only; do not send again at the repeated hour. Test both policies.

Use the same backend calendar logic for dispatch and the UI's next-delivery calculation. Calculating the next occurrence does not require a delivery record.

### 3. 15-Minute Dispatcher

Use Oban's Cron plugin with `*/15 * * * *` to enqueue one shared recurring dispatcher at UTC minutes 00, 15, 30, and 45. This is one logical recurring task, not one task per user or timezone, with 96 scheduled executions per day.

The dispatcher:

1. Determines the current UTC quarter-hour slot and checks that it is within the configured dispatch lateness tolerance.
2. Resolves that slot against the local calendars of active subscriptions, including the daylight saving policy above.
3. Finds matching enabled subscriptions by local weekday, hour, and timezone. Only enqueue when the resolved occurrence equals the UTC slot: the selected local hour starts at minute and second zero, not at every quarter-hour within that hour.
4. Selects the occurrence's quote and enqueues independent Oban delivery jobs in bounded batches.

Use indexed queries and bounded batches rather than loading all subscriptions into memory. Coordinate concurrent dispatcher executions and configure occurrence-based Oban job uniqueness to reduce duplicate enqueueing. Do not assume job uniqueness guarantees exactly-once external sending.

Do not rely on the dispatcher starting at the exact scheduled second or on Cron replaying ticks missed during downtime. Do not replay previous slots or run startup catch-up. A delayed dispatcher outside the current slot's lateness tolerance does no work. If dispatch stops partway through batching, unqueued notifications may be lost; no checkpoint or reconciliation process is required.

### 4. Delivery Jobs Instead of Delivery Records

Use Oban's persistent jobs as the execution records. Do not create a separate `notification_deliveries` table. Each job contains only the non-secret data needed to identify and preserve its occurrence:

- `subscription_id`
- `scheduled_for`, the intended UTC instant
- Local occurrence date
- Selected quote reference and notification locale
- `expires_at`, the latest instant at which a send attempt may start

Configure delivery-job uniqueness using the subscription and scheduled instant, with a uniqueness period and job states covering the dispatch and retry windows. Validate the chosen Oban mechanism under concurrent enqueueing; it is not a replacement for provider idempotency or a permanent occurrence ledger.

There is no delivery-record/job pair to create atomically. Enqueue jobs directly in bounded batches. Keep the full subscription and mail transport credentials out of job arguments; workers load the subscription and resolve the current verified email address from its user.

Choose the quote using the occurrence's local date, not the worker's execution date. Persist the quote reference and locale in job arguments so retries do not select another quote or inherit a process-default language.

### 5. Queue and Email Worker

Keep scheduling rules independent of Swoosh and transport details. The email worker uses the existing mailer through a notification-specific delivery boundary; do not introduce provider-specific adapters or shared-channel integration contracts.

Use one dedicated Oban queue, `notifications_email`.

Each job sends one email through the existing Swoosh mailer. Configure queue concurrency to protect mail transport capacity.

- Retry transient failures a limited number of times with short backoff, within a seconds-to-minutes delivery window rather than on the following day. Configure both attempt limits and an expiry deadline; attempt count alone does not bound elapsed time.
- Check `expires_at` before every send attempt, including the first. Discard expired work without sending, even if it remained queued during downtime. Exhausted or expired notifications are lost, with no compensating resend.
- Treat permanent address or authorization failures separately from transient transport errors.
- Respect mail transport limits; queue concurrency alone is not a rate limiter.
- Recheck subscription eligibility and account email verification before sending, so disabled or changed subscriptions do not blindly send stale pending jobs.
- Reuse Swoosh and the existing mailer for email, keeping quote delivery separate from account authentication messages.
- Keep transport credentials out of job arguments and logs.

Mail transport acceptance is distinct from confirmed recipient delivery. Report only outcomes supported by transport evidence. Job execution state and non-secret telemetry are sufficient for the initial implementation; there is no separate application delivery history or recipient-receipt tracking.

Oban job uniqueness does not guarantee exactly-once external sending. The mail transport may accept a message before the worker loses its response. Use a stable subscription-and-occurrence idempotency key where supported; otherwise accept the residual duplicate risk.

### 6. Missed Sends and Observability

Accept the loss of notifications whose slots were missed during downtime, whose dispatch batches were not enqueued, or whose jobs expire or exhaust attempts. Do not persist dispatcher progress, scan historical intervals, or create replacement jobs for lost notifications.

Already enqueued jobs survive restarts through Oban, but may only send before their original expiry. Avoid creating retroactive occurrences for newly created or edited subscriptions. Exact pending-job invalidation rules remain to be defined before release.

Monitor queue backlog, delivery delay relative to `scheduled_for`, retry counts, permanent failures, expired jobs, and dispatcher execution. Define retention and pruning for Oban jobs before production rollout; job history is not a permanent delivery audit trail.

## Consequences

### Positive

- Uses the existing PostgreSQL infrastructure without a separate broker.
- Keeps recurring scheduling centralized and independent of individual delivery outcomes.
- Supports controlled email queue concurrency and additional worker instances.
- Preserves users' local calendar intent without separate delivery-ledger or dispatch-progress tables.

### Negative / Risks

- The dispatcher runs four times per hour instead of once, increasing lookup frequency while keeping one shared recurring task.
- Scheduling accuracy depends on dispatcher availability and queue capacity; exact-time delivery is not guaranteed.
- Missed slots, partial dispatch batches, and exhausted or expired sends are intentionally not recovered.
- Delivery history is limited to retained Oban jobs and telemetry; there is no durable application audit ledger.
- Subscription edits, expiry checks, and concurrent enqueueing still require careful handling.
- Daylight saving transitions and mail transport idempotency remain explicit correctness concerns.

## Verification Criteria

- Unit tests cover local weekday/date boundaries, daylight saving transitions, invalid timezone identifiers, whole-hour local occurrences in half-hour and quarter-hour offset zones, and quote selection for the occurrence date.
- Integration tests cover one email subscription per user, disabled incomplete schedules, concurrent enqueueing, and subscription changes.
- Dispatcher tests cover exact occurrence matching without additional sends on adjacent quarter-hour ticks, bounded batching, delayed ticks, missed slots without replay, and partial failures without catch-up requirements.
- Worker tests cover email delivery, transient and permanent failures, short bounded retries, expiry before the first attempt and after downtime, and idempotency where supported.
- Tests use controlled time and mail transport responses rather than real provider calls or sleeps.

## Open Decisions Before Release

- Dispatch lateness tolerance, short delivery expiry window, maximum attempts, and backoff values
- Exact invalidation rules for pending deliveries after subscription edits
- Mail transport rate limits and credentials
- Oban job retention period and uniqueness configuration

Separate destination tables, delivery ledgers, and dispatcher checkpoints are not open implementation decisions. Reintroduce them only after an explicit requirements change and ADR revision.

## Alternative Revisit Triggers

- Scheduling precision finer than 15 UTC minutes requires a more frequent dispatcher.
- Users need multiple schedules per user or minute-level scheduling.
- Measured fan-out, queue delay, or database contention exceeds the capacity of this design.
- Mail transport constraints require different batching or delivery infrastructure.
- Requirements change to demand missed-slot recovery, longer-lived retries, a durable delivery audit, or multiple schedules per destination. Only then reconsider the deliberately omitted tables and recovery mechanisms.
