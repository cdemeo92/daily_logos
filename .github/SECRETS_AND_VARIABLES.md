# GitHub Secrets and Variables

## Overview

With Render Deploy Hook deployment, GitHub Secrets are **minimal** - only 1 secret needed!

All other configuration (DATABASE_URL, SECRET_KEY_BASE, etc) is set directly on **Render dashboard**, not in GitHub.

---

## GitHub Secrets (Sensitive Data)

Go to **Settings → Secrets and variables → Actions** → **Secrets** tab

| Secret               | Source                                                   | Purpose                   |
| -------------------- | -------------------------------------------------------- | ------------------------- |
| `RENDER_DEPLOY_HOOK` | https://dashboard.render.com → Web Service → Deploy Hook | Trigger Render deployment |

**That's it.** Only 1 secret needed!

---

## Render Dashboard Configuration

All sensitive data and environment variables go directly on **Render Dashboard**:

1. Go to https://dashboard.render.com
2. Select your **Web Service**
3. Go to **Environment**
4. Add these variables:

| Variable          | Value                                                | Sensitive? |
| ----------------- | ---------------------------------------------------- | ---------- |
| `DATABASE_URL`    | `postgresql://postgres:PASSWORD@HOST:6543/postgres`  | 🔒 Yes     |
| `SECRET_KEY_BASE` | Output from: `mix phx.gen.secret`                    | 🔒 Yes     |
| `PHX_SERVER`      | `true`                                               | ❌ No      |
| `PHX_HOST`        | Your domain (e.g., `daily-logos-xxxxx.onrender.com`) | ❌ No      |

---

## Generating SECRET_KEY_BASE

Run once, locally:

```bash
mix phx.gen.secret
# Output: abc123def456...
```

Copy the output to Render **Environment** as `SECRET_KEY_BASE`.

⚠️ **Important:**

- Generate once and keep forever
- Don't change it (logs out all users, breaks encrypted data)
- Keep it safe in Render (sensitive field)

---

## Supabase DATABASE_URL

Format:

```
postgresql://postgres:PASSWORD@HOST:PORT/postgres
```

For Supabase:

- **HOST**: `db.PROJECT_ID.supabase.co` (from Supabase dashboard)
- **PORT**: `6543` (connection pooler)
- **PASSWORD**: Your Supabase database password (set when creating project)

Example:

```
postgresql://postgres:my_super_secret@db.abcxyz123456.supabase.co:6543/postgres
```

Find yours:

1. Go to https://supabase.com/dashboard
2. Select project
3. Settings → Database → Connection string (Drizzle/Pooler)
4. Copy and paste into Render

---

## Why GitHub Secrets Are Minimal Now

**Before (with Terraform):**

- Terraform needed API keys for Render, Supabase, Cloudflare
- GitHub Actions had to create/update all infrastructure
- Many secrets and variables required

**Now (with Render Deploy Hook):**

- Infrastructure is created manually on Render (one-time setup)
- GitHub Actions only builds Docker image and triggers redeploy
- Only need the Deploy Hook URL (which is a secret)
- Everything else is Render-specific configuration

---

## Setup Checklist

- [ ] Create Render web service manually (https://dashboard.render.com)
- [ ] Set **DATABASE_URL** on Render → Environment
- [ ] Set **SECRET_KEY_BASE** on Render → Environment
- [ ] Set **PHX_SERVER=true** on Render → Environment
- [ ] Copy **Deploy Hook** URL from Render
- [ ] Add `RENDER_DEPLOY_HOOK` as GitHub Secret
- [ ] Push to main branch → GitHub Actions tests → Deploy → Done ✅

---

## Troubleshooting

**"RENDER_DEPLOY_HOOK not set"**

- GitHub Actions skips deploy step if secret is missing (safe fallback)
- Add the secret to GitHub repo settings

**"Database connection error at startup"**

- Check Render logs: dashboard → Web Service → Logs
- Verify `DATABASE_URL` is correct and connection is working
- Test locally: `psql "postgresql://..."`

**"Migrations failed"**

- Check Render logs
- DATABASE_URL might be wrong
- Database might be offline or not accessible from Render region
