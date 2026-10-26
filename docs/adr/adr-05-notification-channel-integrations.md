# ADR-05: Non-Email Notification Channels

## Status

Rejected

## Context

Slack, Discord, and other non-email destinations were considered for daily quote notifications. They would add provider credentials, channel ownership and duplicate-delivery rules, provider-specific rate limits, secret-handling requirements, and additional UI and operational work.

The notification product is limited to each user's verified account email. Shared-channel publishing, bots, direct messages, and other notification providers are out of scope.

## Decision

Do not implement Slack, Discord, Telegram, or other non-email notification destinations. Do not add webhook or OAuth connection flows, provider adapters, provider queues, or channel-specific credential storage.

Deliver notifications only to the user's verified account email through the existing Swoosh mailer, following the scheduling and best-effort delivery rules in [ADR-04](adr-04-notification-scheduling-and-delivery.md).

The deployed `notification_subscriptions` migration contains a `provider` discriminator that can represent more than email. That schema shape is a compatibility artifact of the already-applied migration, not a supported product capability. Do not rewrite that migration; any database constraint changes require a new migration.

## Consequences

### Positive

- No provider connection, webhook-secret, OAuth, or bot lifecycle is required.
- No shared-channel ownership or duplicate-publication policy is required.
- No provider-specific API rate-limit coordination is required.
- Notification preferences remain focused on one verified destination per user.

### Negative

- Users cannot send quotes to Slack, Discord, Telegram, or shared channels.
- Adding another provider later requires an explicit requirements change and a new decision covering authorization, storage, delivery, rate limits, and UI.

## Revisit Trigger

Reconsider only if product requirements explicitly add a non-email destination. Until then, channel integrations are rejected scope, not pending implementation work.
