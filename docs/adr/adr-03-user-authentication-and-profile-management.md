# ADR-03: User Authentication and Profile Management

## Status

Accepted

## Context

Daily Logos currently has no user domain implementation yet (Phase 2 in roadmap).

Current requirements for this phase:

- User registration with email/password
- User registration/login with social providers: Google, Facebook, LinkedIn, GitHub
- Login/logout flows
- Email verification required after registration
- User profile self-management:
  - username change
  - email change
  - password change

Near-future requirement to keep in mind (not in scope for immediate delivery):

- User-configurable notification preferences and channel settings (email and other channels)

Constraints and project context:

- Phoenix 1.8 application with Ecto + PostgreSQL
- Existing architecture favors clear boundaries around the users domain in this phase
- Team wants to avoid hard lock-in where practical and keep migration options open

## Options Considered

### Option A: Supabase Auth as Identity Provider + Local App User Model

Use Supabase Auth for identity lifecycle (signup, signin, password reset, email verification, OAuth providers), while keeping application user data and preferences in project-owned tables.

#### High-level model

- Identity authority: Supabase (`auth.users`)
- App-owned tables in `public` schema (managed by this codebase migrations):
  - `users` (internal app user)
  - `user_identities` (provider mapping)
  - `user_profiles` (username and profile data)

#### Pros

- Fastest path to deliver required auth features
- Built-in email verification and password recovery flows
- Native support for major OAuth providers; manageable config for GitHub/Google/Facebook/LinkedIn
- Reduces security surface area handled directly by the app
- Keeps app-domain data ownership local and migratable

#### Cons

- Dependency on Supabase Auth operationally
- Some lock-in around token claim shape and auth ergonomics
- Need careful design to keep app logic independent from Supabase internals

### Option B: Full Native Phoenix Auth Stack (phx.gen.auth + Ueberauth providers) (Chosen)

Use internal user/password auth with local password hashing and add each social login via Ueberauth strategies.

#### Pros

- Maximum ownership and minimal external lock-in
- Full flexibility in auth flow and data model
- Email verification flow can be enforced directly in app logic from day one

#### Cons

- Higher implementation and maintenance effort
- Larger security responsibility (password auth, recovery, verification, provider edge cases)
- Slower time-to-market compared to managed auth

### Option C: Third-Party Dedicated IdP (Auth0/Clerk/Keycloak SaaS)

Adopt a dedicated identity provider outside Supabase.

#### Pros

- Rich enterprise identity features and dashboards
- Potentially easier multi-app SSO evolution

#### Cons

- Additional vendor and cost surface
- Integration complexity for current project scope
- No meaningful advantage for immediate requirements vs Supabase Auth already in use

## Decision

Choose **Option B**: full native Phoenix auth using `phx.gen.auth` for email/password and confirmation lifecycle, plus `Ueberauth` strategies for social login providers.

This gives the best balance for current needs:

- no dependency on an external auth provider for core identity
- strong control over domain model, session rules, and security flows
- migration-free future for auth storage because users are first-class local records

## Decision Details

### 1. Identity and domain ownership

- `users` is the primary identity table in local PostgreSQL.
- `user_identities` links local users to social providers (`google`, `facebook`, `linkedin`, `github`).
- `user_profiles` stores username and profile data.

All business logic for this phase remains inside the users domain boundary.

### 2. Email verification

- Email/password registration must create user in unconfirmed state.
- Confirmation email is sent on signup with one-time token and expiry.
- Login with email/password is denied until confirmation is completed.
- Protected routes require confirmed account for full access.
- Resend-confirmation flow must be available.

For social login:

- If provider returns a verified email claim, treat identity as confirmed.
- If provider does not provide verified email, require local email confirmation before enabling full account access.

### 3. Profile management ownership

- `username` and app profile attributes live in local DB (`user_profiles`).
- Email/password lifecycle is managed in local auth modules (`phx.gen.auth` foundation).
- Email change flow must always require re-verification of the new email.

### 4. Social providers

- Enable and configure OAuth providers via `Ueberauth` + provider strategies.
- LinkedIn support should be validated early in staging due provider-specific constraints.

### 5. Migration-aware boundary

- Introduce an `Accounts` context interface in Phoenix (port):
  - `register_with_email/1`
  - `login_with_email/1`
  - `oauth_callback/2`
  - `change_email/2`
  - `change_password/2`
  - `confirm_user/1`
  - `resend_confirmation_instructions/1`
  - `upsert_profile/2`
- Keep controllers/liveviews dependent on context contract, not provider SDK details.

## Consequences

### Positive

- Delivers required functionality with low risk and good velocity
- Preserves clean architecture boundaries
- Keeps future notification model cleanly attachable to app user

### Negative / Risks

- OAuth provider setup/testing matrix increases complexity
- Security ownership for auth lifecycle is fully on the team

### Mitigations

- Reuse `phx.gen.auth` baseline flows and keep customizations small and explicit
- Add integration tests for token expiry/confirmation/login restrictions
- Apply standard security checks (rate limits, secure token handling, CSRF, session hardening)

## Implementation Plan (Incremental)

### Phase 1 (in scope now)

1. Add `users`, `user_identities`, `user_profiles` tables via Ecto migrations.
2. Generate native auth foundation with `phx.gen.auth` and integrate it into the `Accounts` context.
3. Build auth flows:
   - email signup/login
   - social login (Google, Facebook, LinkedIn, GitHub)
   - logout
4. Enforce email verification:

- block email/password login until confirmed
- send confirmation email on signup
- support resend confirmation
- require re-verification on email change

5. Build profile settings pages:
   - username update
   - email change trigger
   - password change trigger
6. Add tests for:
   - registration/login success and failure
   - unverified user restrictions

- confirmation token validity/expiry
- profile update authorization

### Phase 2 (future, out of immediate scope)

1. Add `notification_preferences` table keyed by `users.id`.
2. Add channel preference model and opt-in semantics.
3. Integrate delivery systems (email first, others later).

## Alternative Revisit Triggers

Revisit this ADR if any of the following occurs:

- Team cannot sustainably maintain auth security/operations in-house
- Provider limitations make one or more required social flows unreliable (especially LinkedIn)
- Product evolves into multi-app SSO that justifies dedicated enterprise IdP

## Notes

- Current gap: a production transactional email provider is not configured yet. Local development preview/mailbox is available, but real confirmation email delivery requires selecting and configuring a provider plus DNS email authentication records.
