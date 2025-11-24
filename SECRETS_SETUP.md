# 🔒 Secrets Setup Guide

## Why This Matters

**NEVER commit secrets to Git!** This guide shows you how to keep your OAuth credentials secure.

## 🚀 Quick Setup

### Step 1: Copy the Template

```bash
cp .env.example .env
```

### Step 2: Fill in Your Values

Edit `.env` with the credentials provided by Carbon Voice API team:

```env
OAUTH_CLIENT_ID=carbon_voice_app_12345
OAUTH_CLIENT_SECRET=sk_live_abc123xyz789...
OAUTH_REDIRECT_URL=carbonvoiceapp://oauth/callback
OAUTH_AUTH_URL=https://auth.carbonvoice.io/oauth/authorize
OAUTH_TOKEN_URL=https://auth.carbonvoice.io/oauth/token
API_BASE_URL=https://api.carbonvoice.io/v1
```

### Step 3: Run Your App

**Option A: Using the helper script (recommended)**

```bash
./run_with_secrets.sh
```

**Option B: Manual flutter run**

```bash
flutter run \
  --dart-define=OAUTH_CLIENT_ID="your_client_id" \
  --dart-define=OAUTH_CLIENT_SECRET="your_secret" \
  --dart-define=OAUTH_REDIRECT_URL="your_redirect_url" \
  --dart-define=OAUTH_AUTH_URL="your_auth_url" \
  --dart-define=OAUTH_TOKEN_URL="your_token_url" \
  --dart-define=API_BASE_URL="your_api_base_url"
```

## 🛡️ Security Checklist

- ✅ `.env` is in `.gitignore` (already done)
- ✅ `.env.example` has no real secrets (safe to commit)
- ✅ `oauth_config.dart` uses `String.fromEnvironment()`
- ✅ Never hardcode secrets in source code

## 🔍 Verify It's Working

Check that secrets are not tracked by Git:

```bash
git status
```

You should see:
- ✅ `.env.example` (can be staged/committed)
- ❌ `.env` (should NOT appear - it's gitignored)

## 📝 For Team Members

When someone clones this repo, they should:

1. Copy `.env.example` to `.env`
2. Ask the team lead for the actual credentials
3. Fill in their `.env` file
4. Run using `./run_with_secrets.sh`

## 🏗️ For CI/CD (Later)

When setting up CI/CD, use encrypted secrets:
- GitHub Actions: Use repository secrets
- GitLab CI: Use CI/CD variables
- Codemagic: Use environment variables

## ⚠️ What If I Accidentally Committed Secrets?

1. **Rotate credentials immediately** (get new ones from Carbon Voice team)
2. Remove from Git history:
   ```bash
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch .env" \
     --prune-empty --tag-name-filter cat -- --all
   ```
3. Force push (⚠️ coordinate with team first)

## 📚 Learn More

- [Flutter build-time secrets](https://dartcode.org/docs/using-dart-define-in-flutter/)
- [OAuth 2.0 best practices](https://oauth.net/2/)

