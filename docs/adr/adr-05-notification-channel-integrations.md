# ADR-05: Notification Channel Integrations with Ports and Adapters

## Status

Accepted

## Context

Daily Logos needs personal notification delivery through email and publication to shared Slack and Discord channels. Users must be able to connect multiple shared-channel destinations within the same provider.

Only integrations without messaging API fees, operating within provider free limits, are in scope. WhatsApp is excluded because of messaging costs. Telegram is excluded because its free per-bot broadcast throughput does not meet the desired peak-delivery expectations. Slack and Discord throughput must still be validated; neither is assumed to support unlimited simultaneous delivery.

Bot-based personal notifications on Slack and Discord are excluded. Discord has a global per-bot API limit and additional DM access restrictions; Slack personal delivery is subject to aggregate workspace limits. Shared-channel publication reduces fan-out by sending one message for all channel members, but does not eliminate provider rate limits.

Provider authorization, destination permissions, credentials, message formats, and failure responses differ. These differences must not spread into the scheduling domain or couple business rules to provider APIs.

This ADR covers channel operation, authorization, destination modeling, and ports-and-adapters boundaries. It does not describe pages or UI layout.

## Relationship to ADR-04

[ADR-04](adr-04-notification-scheduling-and-delivery.md) remains authoritative for hourly dispatch, occurrence generation, Oban delivery jobs, short bounded retries, and expiry. Missed slots are not recovered.

Subscriptions target individual connected destinations, not just providers. Destination configuration and its single calendar share one `notification_subscriptions` row. There are no separate destination, delivery-ledger, or dispatcher-progress tables. Provider queues are email, Slack, and Discord.

[Notifications UI](../NOTIFICATIONS_UI.md) defines manual webhook entry instead of OAuth installation for this implementation. OAuth provisioning and shared-installation infrastructure are not required.

## Options Considered

### Option A: Direct Provider Calls from Controllers and Workers

- Initially requires fewer boundaries.
- Couples use cases to provider authentication, payloads, and errors.
- Makes isolated tests and provider changes harder.

### Option B: Ports and Provider-Specific Adapters (Chosen)

- Keeps scheduling and eligibility rules independent of providers.
- Normalizes delivery outcomes without hiding provider capabilities.
- Supports isolated domain tests and adapter contract tests.
- Requires explicit contracts and dependency configuration.

### Option C: One Universal Integration Contract

- Appears to simplify all integrations behind one interface.
- Conflates OAuth installation, webhook provisioning, and delivery.
- Forces unsupported capabilities or provider-specific branches into the shared contract.

## Decision

Use a pragmatic hexagonal architecture with application use cases, explicit ports where an external boundary exists, and provider-specific adapters.

Use the existing Swoosh mailer for personal email and official Slack and Discord incoming webhooks through Req for shared channels. Do not implement bot-based sending or personal Slack/Discord conversations.

Users supply supported incoming-webhook URLs through the Notifications page. Daily Logos does not implement an OAuth installation flow or need provider applications merely to execute these webhooks. Users do not supply bot tokens or install bots for notification delivery. Creating a webhook on the provider side remains subject to provider setup and permissions.

## Decision Details

### 1. Integration and Destination Model

Distinguish these concepts:

| Concept      | Responsibility                                                                 |
| ------------ | ------------------------------------------------------------------------------ |
| Provider     | Email, Slack, or Discord                                                       |
| Integration  | Provider connection, protected webhook configuration, and credential lifecycle |
| Destination  | A verified email address or a specific shared Slack or Discord channel         |
| Subscription | Local calendar settings for a connected destination                            |

A user can connect multiple destinations for the same provider, including channels across different workspaces or servers. Start with one subscription per destination connected by that user, rather than one subscription per provider.

These are domain concepts, not a requirement for separate tables. Store the destination, protected connection configuration, and calendar in one `notification_subscriptions` row. Resolve email from the verified account rather than duplicating its address. Connection edits and calendar edits use separate application operations and changesets even though they update the same row.

Each Oban delivery job identifies the subscription and occurrence; the adapter resolves the current destination through that subscription. Keep provider channel identity separate from authorization credentials: different webhooks may address the same external channel.

Subscriptions and their stored webhook configuration belong to the authenticated user. Deleting a subscription removes its local configuration, not the external webhook or another user's connection. Shared OAuth installations and their lifecycle are outside this implementation.

### 2. Ports and Adapters

- **Domain:** destination and subscription eligibility, occurrence rules, and provider-independent delivery concepts. No dependency on Phoenix, Oban, Req, Swoosh, or provider payloads.
- **Application:** use cases for connecting destinations, verifying access, disconnecting integrations, and delivering an occurrence. These orchestrate domain rules and ports.
- **Inbound adapters:** authenticated notification forms and Oban workers. They authenticate or validate input and invoke application use cases.
- **Outbound adapters:** Ecto/PostgreSQL persistence, Oban enqueueing, Swoosh email, Slack APIs, and Discord APIs.

Express suitable port contracts with Elixir behaviours and select implementations at the application composition boundary. Do not introduce wrappers that add no meaningful boundary.

The delivery port accepts a provider-independent message and destination reference, and returns normalized outcomes: provider acceptance, transient failure, rate limiting with retry guidance, or permanent failure. Provider adapters resolve credentials and construct provider-specific payloads.

Keep connection configuration separate from delivery. Account email verification and manual webhook configuration do not need to implement an identical contract.

Enqueue Oban delivery jobs directly as described in ADR-04. Do not add a delivery-record/job transaction, a separate delivery ledger, or a dispatcher checkpoint. Those mechanisms belong to the superseded recovery design, not this best-effort implementation.

### 3. Email

- Use the existing verified account email and mailer infrastructure.
- Reuse Swoosh through a notification delivery adapter, separate from authentication message orchestration.
- Recheck destination validity after account email changes; do not silently continue sending to an outdated address.
- This decision introduces no new messaging service or paid email integration. Existing mail transport capacity and operating costs remain separate concerns.

### 4. Slack Shared Channels

- Accept an official incoming-webhook URL obtained by the user through Slack's webhook setup.
- Collect the URL and a user-defined destination name; do not promise workspace or channel-name discovery from the URL.
- Do not implement OAuth installation or request provider tokens in Daily Logos.
- Send messages by HTTPS POST to the stored webhook URL.
- Configure a separate webhook for each connected channel. Private channels require appropriate membership and authorization.
- The webhook URL is a credential, not the channel's ordinary URL. Protect it accordingly.

Accept supported webhook URLs for external workspaces, not just the development workspace. Workspace policies, administrator approval, and free-plan integration limits may prevent users from creating a webhook; explain these restrictions without requiring a paid upgrade.

Do not request `im:write`, `chat:write`, or message-history permissions for this webhook-only integration.

### 5. Discord Shared Channels

- Accept an official incoming-webhook URL created and copied by a user with the required Discord channel permissions.
- Collect the URL and a user-defined destination name; do not implement OAuth provisioning in Daily Logos.
- Send messages through the execute-webhook API, using `wait=true` to obtain confirmation and the created message when successful.
- No server bot installation is required for this mode.

Support multiple channels by storing each destination and its webhook separately. Restrict allowed mentions so notification content does not unexpectedly notify roles or all server members.

Do not request bot installation or personal-conversation access. Users do not need to share a server with a Daily Logos bot or join a Daily Logos server.

### 6. Credential and Connection Lifecycle

- Bind connection creation, edits, and deletion to the authenticated account using the current scope.
- Accept only supported HTTPS provider hosts and webhook paths; reject provider mismatches and do not follow redirects to untrusted hosts. A webhook is not an arbitrary server-side HTTP destination.
- Syntactic validation does not prove delivery access. Do not send test messages automatically when saving or label a saved webhook as delivery-verified.
- Encrypt persisted webhook secrets and redact them from inspected structures.
- Never expose credentials in job arguments, client responses, logs, or delivery metadata.
- Never return an existing webhook secret for editing; replacements accept a new URL without redisplaying the old one.
- Track known unusable or revoked connections and recheck eligibility before sending pending jobs.
- Distinguish deleting local subscription configuration from revoking an external webhook that may have other consumers.

### 7. Throughput and Delivery Outcomes

Use the channel queues and delivery lifecycle from ADR-04. Apply rate limits at the scopes actually enforced by each provider, such as webhook, channel, workspace, route, or source IP, coordinating across worker instances when necessary.

- Slack generally permits one message per second per channel, including incoming webhooks. Do not assume webhook URLs bypass aggregate workspace restrictions or rely on undocumented burst capacity.
- Discord exposes per-route and webhook-resource quotas through `X-RateLimit-*` headers. Requests without an `Authorization` header are also subject to an IP-based global limit; webhook destinations must not be treated as unlimited independent capacity.
- One publication reaches all members of a shared channel. Different channels still require separate requests, so a large number of destinations scheduled for the same hour can introduce queue delay.

Queue concurrency is not a rate limiter. Respect provider retry guidance and defer work through Oban rather than sleeping in workers. If provider guidance would delay a send beyond its expiry, discard it instead of retrying early or extending the deadline. Confirm free-tier peak capacity against expected subscriber volumes before release.

Keep provider acceptance distinct from recipient receipt or a device push notification. The user's provider notification settings remain outside Daily Logos' control. Do not promise exactly-once external sending where the provider does not support idempotency.

All members see the same scheduled channel publication; this is not an individual local-time notification for each member.

For shared channels, identify the destination using provider and external workspace/server/channel IDs, not webhook secrets. Define a destination-level ownership and duplicate-prevention policy before release so multiple user connections do not unintentionally publish the same occurrence repeatedly. Do not collapse intentionally different schedules or languages without an explicit rule.

## Consequences

### Positive

- Provider-specific authorization and sending stay outside scheduling rules.
- Users can connect multiple shared channels through manually configured webhooks without bot-based delivery or a Daily Logos OAuth installation flow; personal delivery remains available through email.
- Provider adapters can be tested and changed independently.
- No additional external broker or paid messaging integration is introduced.

### Negative / Risks

- Free provider limits still constrain throughput and installation availability.
- Workspace/server permissions, installation policies, and revoked webhooks can block otherwise valid subscriptions.
- Shared-channel destinations require explicit duplicate-prevention rules even though local subscriptions are user-owned.
- Ports add contracts that must remain small and aligned with actual capabilities.

## Verification Criteria

- Unit tests exercise application cases with substitute ports, without network calls.
- Adapter contract tests cover message formatting and normalized acceptance, transient errors, permanent errors, and rate-limit outcomes.
- Integration tests cover provider URL validation, unsafe host and redirect rejection, credential protection, unusable connections, and subscription ownership.
- Tests cover multiple destinations per provider, independent calendar and connection edits on the same subscription row, and deletion without revoking externally shared webhooks.
- Shared-channel tests cover duplicate connections without unintentionally suppressing distinct intended publications.
- Validate user-supplied Slack and Discord incoming webhooks with controlled real test environments before release; form saves do not automatically send messages.
- Verify that Slack and Discord integrations do not require an application OAuth flow, bot tokens, or DM permissions and reject unsupported destination types.
- Worker tests verify that rate-limit deferrals and retries respect ADR-04's short expiry window; expired or exhausted sends are not recovered.
- Measure peak throughput using only the supported free provider limits.

## Open Decisions Before Release

- Exact shared-channel duplicate-prevention semantics
- Expected peak volumes, acceptable delivery delay, and provider rate-limit configuration

Separate destination tables, shared OAuth installation infrastructure, delivery ledgers, and dispatcher recovery are not pending implementation tasks. Reconsider them only after an explicit requirements change and ADR revision.

## References

- [ADR-04: Notification Scheduling and Delivery](adr-04-notification-scheduling-and-delivery.md)
- [Slack OAuth installation](https://docs.slack.dev/authentication/installing-with-oauth)
- [Slack incoming webhooks](https://docs.slack.dev/messaging/sending-messages-using-incoming-webhooks)
- [Slack rate limits](https://docs.slack.dev/apis/web-api/rate-limits/)
- [Discord OAuth and webhook authorization](https://docs.discord.com/developers/topics/oauth2#webhooks)
- [Discord webhook API](https://docs.discord.com/developers/resources/webhook)
- [Discord rate limits](https://docs.discord.com/developers/topics/rate-limits)
