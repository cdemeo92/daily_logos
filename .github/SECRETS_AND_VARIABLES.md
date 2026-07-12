# GitHub Secrets and Variables

## Setup

### Secrets

Go to **Settings → Secrets and variables → Actions** (Secrets tab)

### Variables

Go to **Settings → Secrets and variables → Actions** (Variables tab)

---

## Required Secrets (Sensitive Data)

Store in **Secrets** - always masked in logs, never exposed

| Secret                  | Source                                         | Type              |
| ----------------------- | ---------------------------------------------- | ----------------- |
| `RENDER_API_KEY`        | https://dashboard.render.com/api-tokens        | API Key           |
| `SECRET_KEY_BASE`       | Generated: `mix phx.gen.secret`                | Encryption Key    |
| `DATABASE_URL`          | Supabase project connection string             | Connection String |
| `SUPABASE_ACCESS_TOKEN` | https://supabase.com/dashboard/account/tokens  | API Token         |
| `SUPABASE_DB_PASSWORD`  | Set when creating Supabase project             | DB Password       |
| `CLOUDFLARE_API_TOKEN`  | https://dash.cloudflare.com/profile/api-tokens | API Token         |

---

## Configuration Variables (Non-Sensitive)

Store in **Variables** - visible in logs but safe to expose

| Variable                   | Value                                                        | Type              |
| -------------------------- | ------------------------------------------------------------ | ----------------- |
| `RENDER_OWNER_ID`          | From https://dashboard.render.com/account (format: usr-xxxx) | Owner ID          |
| `RENDER_PLAN`              | `starter`, `standard`, or `pro`                              | Compute Tier      |
| `RENDER_REGION`            | `oregon`, `singapore`, or `frankfurt`                        | Geographic Region |
| `SUPABASE_ORGANIZATION_ID` | From https://supabase.com/dashboard/settings/organizations   | Org ID            |
| `SUPABASE_REGION`          | `us-east-1`, `eu-west-1`, etc.                               | Database Region   |
| `CLOUDFLARE_ACCOUNT_ID`    | From https://dash.cloudflare.com/ (bottom left)              | Account ID        |
| `CLOUDFLARE_ZONE_NAME`     | Your domain (e.g., example.com)                              | DNS Zone          |
| `FEEDBACK_FORM_URL`        | e.g., https://forms.example.com/feedback                     | URL               |
| `BUY_ME_COFFEE_URL`        | e.g., https://buymeacoffee.com/yourname                      | URL               |

---

## Why the distinction?

**Secrets** (in GitHub Secrets):

- ✅ Always masked in logs and web UI
- ✅ Can't be accessed by pull requests from forks
- ✅ If leaked, full compromise (API keys, credentials)

**Variables** (in GitHub Variables):

- ✅ Simplifies pull request testing
- ✅ Non-sensitive configuration visible for debugging
- ✅ If leaked, only exposes configuration (no keys or passwords)

---

## Supabase Setup

`DATABASE_URL` è memorizzato come GitHub Secret (valido per tutti i deployment):

**Format:**

```
postgresql://postgres:PASSWORD@db.PROJECT_ID.supabase.co:5432/postgres
```

**How to find it:**

1. Go to https://supabase.com/dashboard
2. Select your project → Settings → Database
3. Copy the "PostgreSQL" connection string (5432 port - direct connection)
4. Save it as `DATABASE_URL` secret in GitHub

⚠️ **Important:**

- Use **port 5432** (direct connection) for migrations and deployments
- Use **port 6543** (pooler) only for long-lived app connections
- Keep this URL secret (contains your database password)

---

## Generating SECRET_KEY_BASE

⚠️ **Do this ONCE, before first deploy:**

```bash
mix phx.gen.secret
# Output: abc123def456...
```

Copy the output and save it as `SECRET_KEY_BASE` in GitHub Secrets. **Keep this value forever - never change it.**

❌ **Do NOT:**

- Regenerate it (logs out all users, breaks encrypted data)
- Commit it to `.env` or code
- Change it between deploys
