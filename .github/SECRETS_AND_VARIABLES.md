# GitHub Secrets and Variables

## Setup

### Secrets
Go to **Settings → Secrets and variables → Actions** (Secrets tab)

### Variables
Go to **Settings → Secrets and variables → Actions** (Variables tab)

---

## Required Secrets (Sensitive Data)

Store in **Secrets** - always masked in logs, never exposed

| Secret | Source | Type |
|--------|--------|------|
| `RENDER_API_KEY` | https://dashboard.render.com/api-tokens | API Key |
| `SECRET_KEY_BASE` | Generated: `mix phx.gen.secret` | Encryption Key |
| `SUPABASE_ACCESS_TOKEN` | https://supabase.com/dashboard/account/tokens | API Token |
| `SUPABASE_DB_PASSWORD` | Set when creating Supabase project | DB Password |
| `CLOUDFLARE_API_TOKEN` | https://dash.cloudflare.com/profile/api-tokens | API Token |

---

## Configuration Variables (Non-Sensitive)

Store in **Variables** - visible in logs but safe to expose

| Variable | Value | Type |
|----------|-------|------|
| `RENDER_PLAN` | `starter`, `standard`, or `pro` | Compute Tier |
| `RENDER_REGION` | `oregon`, `singapore`, or `frankfurt` | Geographic Region |
| `SUPABASE_ORGANIZATION_ID` | From https://supabase.com/dashboard/settings/organizations | Org ID |
| `SUPABASE_REGION` | `us-east-1`, `eu-west-1`, etc. | Database Region |
| `SUPABASE_PLAN_ID` | `free`, `pro`, or `enterprise` | Plan Type |
| `CLOUDFLARE_ACCOUNT_ID` | From https://dash.cloudflare.com/ (bottom left) | Account ID |
| `CLOUDFLARE_ZONE_NAME` | Your domain (e.g., example.com) | DNS Zone |
| `FEEDBACK_FORM_URL` | e.g., https://forms.example.com/feedback | URL |
| `BUY_ME_COFFEE_URL` | e.g., https://buymeacoffee.com/yourname | URL |

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

## Supabase Setup (via Terraform)

Supabase è gestito interamente da Terraform. Al deploy:

1. Terraform crea il progetto Supabase
2. Genera automaticamente `DATABASE_URL` dalla connessione
3. Passa la URL a Render.com

⚠️ **Conseguenze:**
- ✅ Database sempre in sync con infra
- ✅ Niente credenziali hardcoded
- ❌ Se elimini il Terraform state, il progetto Supabase rimane (dovrai gestirlo manualmente)

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
