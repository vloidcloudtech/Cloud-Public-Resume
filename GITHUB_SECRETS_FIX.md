# GitHub Secrets Naming Fix

## Issue

GitHub has a restriction that prevents creating secrets with names starting with `GITHUB_`. This causes errors when trying to create secrets like `GITHUB_TOKEN_PAT` or `GITHUB_USERNAME`.

**Error message:**
```
Secret names cannot start with GITHUB_
```

## Solution

All secret names that started with `GITHUB_` have been renamed to use the `GH_` prefix instead.

## Updated Secret Names

### Before (❌ Won't Work)

| Old Name | Status |
|----------|--------|
| `GITHUB_TOKEN_PAT` | ❌ Blocked by GitHub |
| `GITHUB_USERNAME` | ❌ Blocked by GitHub |

### After (✅ Works)

| New Name | Purpose |
|----------|---------|
| `GH_PERSONAL_ACCESS_TOKEN` | GitHub Personal Access Token for API access |
| `GH_USERNAME` | Your GitHub username for fetching repositories |

## Complete List of Required Secrets

When setting up GitHub Secrets for your VloidCloudTech portfolio, use these exact names:

### AWS Credentials
1. `AWS_ACCESS_KEY_ID` - AWS IAM access key
2. `AWS_SECRET_ACCESS_KEY` - AWS IAM secret access key

### API Keys
3. `GH_PERSONAL_ACCESS_TOKEN` - GitHub Personal Access Token (repo read scope)
4. `YOUTUBE_API_KEY` - YouTube Data API v3 key
5. `ANTHROPIC_API_KEY` - Anthropic Claude API key for AI summaries

### Content Source Identifiers
6. `GH_USERNAME` - Your GitHub username: `vloidcloudtech`
7. `MEDIUM_USERNAME` - Your Medium username: `@vloidcloudtech`
8. `YOUTUBE_CHANNEL_ID` - Your YouTube channel ID (starts with UC)

## Files Updated

The following files have been updated with the correct secret names:

1. **`.github/workflows/deploy.yml`**
   - Updated workflow to use `GH_PERSONAL_ACCESS_TOKEN` instead of `GITHUB_TOKEN_PAT`
   - Updated workflow to use `GH_USERNAME` instead of `GITHUB_USERNAME`

2. **`GITHUB_SECRETS_SETUP.md`**
   - Updated all documentation references
   - Added warning about GitHub secret naming restrictions

3. **`QUICK_START.md`**
   - Updated quick reference with correct secret names
   - Added important note about naming restrictions

## How to Configure Secrets

### Step 1: Go to GitHub Repository Settings

1. Navigate to your repository: `https://github.com/vloidcloudtech/Cloud-Public-Resume`
2. Click **Settings** (top menu)
3. Click **Secrets and variables** → **Actions** (left sidebar)
4. Click **New repository secret**

### Step 2: Add Each Secret

For each secret in the table above:

1. **Name**: Enter the exact name from the table (e.g., `GH_PERSONAL_ACCESS_TOKEN`)
2. **Secret**: Paste the actual value
3. Click **Add secret**

### Step 3: Verify All Secrets Are Added

After adding all secrets, you should see 8 secrets total:

```
✅ AWS_ACCESS_KEY_ID
✅ AWS_SECRET_ACCESS_KEY
✅ GH_PERSONAL_ACCESS_TOKEN
✅ YOUTUBE_API_KEY
✅ ANTHROPIC_API_KEY
✅ GH_USERNAME
✅ MEDIUM_USERNAME
✅ YOUTUBE_CHANNEL_ID
```

## Example Values (for reference)

**Do not copy these - use your actual values!**

```bash
# AWS Credentials (get from AWS IAM Console)
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

# GitHub PAT (generate at https://github.com/settings/tokens)
GH_PERSONAL_ACCESS_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# YouTube API Key (get from Google Cloud Console)
YOUTUBE_API_KEY=AIzaSyXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxX

# Anthropic API Key (get from https://console.anthropic.com/)
ANTHROPIC_API_KEY=sk-ant-api03-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Content Sources
GH_USERNAME=vloidcloudtech
MEDIUM_USERNAME=@vloidcloudtech
YOUTUBE_CHANNEL_ID=UCxxxxxxxxxxxxxxxxxxxxx
```

## Testing the Fix

After configuring all secrets:

1. **Commit and push** your code to GitHub
2. **Go to Actions tab** in your repository
3. **Watch the workflow run** - it should succeed
4. **Check the logs** for any secret-related errors

## Common Errors and Solutions

### Error: "Secret not found"

**Cause**: Secret name doesn't match what the workflow expects

**Solution**: Verify secret names match exactly (case-sensitive):
- ✅ `GH_PERSONAL_ACCESS_TOKEN`
- ❌ `gh_personal_access_token`
- ❌ `GITHUB_TOKEN_PAT`

### Error: "Invalid AWS credentials"

**Cause**: AWS secrets are incorrect or missing

**Solution**:
1. Go to AWS IAM Console
2. Create new access key
3. Update GitHub secrets with new values

### Error: "403 Forbidden" when accessing GitHub API

**Cause**: GitHub Personal Access Token is invalid or missing `repo` scope

**Solution**:
1. Go to https://github.com/settings/tokens
2. Generate new token with `repo` scope
3. Update `GH_PERSONAL_ACCESS_TOKEN` secret

## Why This Change Was Needed

GitHub reserves the `GITHUB_` prefix for:
- **System-provided secrets**: Like `GITHUB_TOKEN` (auto-generated)
- **GitHub Actions context**: Like `GITHUB_SHA`, `GITHUB_REF`
- **Security**: Prevents confusion with built-in variables

By using `GH_` instead, we:
- ✅ Avoid naming conflicts
- ✅ Follow GitHub best practices
- ✅ Make deployment work smoothly

## Next Steps

After configuring secrets:

1. ✅ All secrets added to GitHub
2. ⏭️ Push code to trigger GitHub Actions
3. ⏭️ Deploy infrastructure with `terraform apply`
4. ⏭️ Website goes live at https://vloidcloudtech.com

For detailed deployment steps, see [QUICK_START.md](QUICK_START.md)

---

**Summary**: Use `GH_` prefix instead of `GITHUB_` for all GitHub-related secret names! 🔐
