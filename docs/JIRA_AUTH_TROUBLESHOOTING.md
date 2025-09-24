# JIRA Authentication Troubleshooting Guide

## 🚨 Current Issue: 403 Forbidden Error

The diagnostics show that your JIRA API token is not working correctly. This is a common authentication issue with JIRA.

## 🔍 Root Cause Analysis

The error occurs because:
1. **Wrong Authentication Method**: JIRA uses Basic Auth, not Bearer tokens
2. **Missing Email**: API tokens need to be paired with your JIRA email
3. **Insufficient Permissions**: Token lacks required scopes
4. **Token Format**: Incorrect token format

## 🛠️ Step-by-Step Solutions

### Solution 1: Set Up Proper Authentication (Recommended)

```bash
# Method 1: Set email and token separately
export JIRA_EMAIL="your-email@domain.com"
export JIRA_API_KEY="your-api-token-here"

# Method 2: Use combined format
export JIRA_API_KEY="your-email@domain.com:your-api-token-here"
```

### Solution 2: Create/Verify JIRA API Token

1. **Go to JIRA Settings:**
   - Click your profile picture → Account Settings
   - Or go to: `https://your-domain.atlassian.net/secure/ViewProfile.jspa`

2. **Create API Token:**
   - Scroll down to "Security" section
   - Click "Create and manage API tokens"
   - Click "Create API token"
   - Give it a label (e.g., "PAWS360 Import")
   - Copy the token immediately (you won't see it again!)

3. **Verify Token Permissions:**
   - Ensure your user account has these permissions in the PGB project:
     - Create Issues
     - Edit Issues
     - Browse Projects

### Solution 3: Check Project Access

1. **Verify Project Key:**
   ```bash
   echo $JIRA_PROJECT_KEY  # Should be "PGB"
   ```

2. **Check Project Permissions:**
   - Go to Project Settings → Permissions
   - Ensure your user has "Create Issues" permission
   - Check if issue types (Epic, Story, Task) are enabled

### Solution 4: Test Authentication

```bash
# Test with curl
curl -u "your-email@domain.com:your-api-token" \
  "https://your-domain.atlassian.net/rest/api/3/myself"

# Should return your user info, not 403
```

## 🔧 Quick Fix Commands

```bash
# 1. Set your credentials
export JIRA_EMAIL="your-actual-email@domain.com"
export JIRA_API_KEY="ATATT3xFfGF0..."

# 2. Run diagnostics again
python jira_diagnostics.py

# 3. Test single item
python csv_to_jira.py --csv jira-import-paws360-transform-student.csv --test-single 1
```

## 📋 Environment Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `JIRA_URL` | Your JIRA instance URL | `https://paw360.atlassian.net` |
| `JIRA_EMAIL` | Your JIRA account email | `user@company.com` |
| `JIRA_API_KEY` | Your API token | `ATATT3xFfGF0...` |
| `JIRA_PROJECT_KEY` | Project key | `PGB` |

## 🐛 Common Issues & Fixes

### Issue: "403 Forbidden"
**Fix:** Check token permissions and email format

### Issue: "401 Unauthorized"
**Fix:** Verify API token is correct and not expired

### Issue: "404 Project not found"
**Fix:** Check JIRA_PROJECT_KEY is correct

### Issue: "Missing required fields"
**Fix:** Ensure CSV has Summary and Issue Type columns

## 🧪 Testing Your Fix

### Step 1: Run Diagnostics
```bash
python jira_diagnostics.py
```

### Step 2: Test Single Item
```bash
python csv_to_jira.py --csv jira-import-paws360-transform-student.csv --test-single 1
```

### Step 3: Full Import (if single test passes)
```bash
python csv_to_jira.py --csv jira-import-paws360-transform-student.csv --create
```

## 📞 Need Help?

If you're still getting errors:

1. **Check JIRA Version:** Some older JIRA instances use different auth methods
2. **Contact Admin:** Your JIRA admin may need to grant additional permissions
3. **Token Scopes:** Ensure token has all necessary API scopes
4. **Network Issues:** Check if your network blocks JIRA API calls

## 🎯 Success Criteria

✅ **Diagnostics pass all tests**  
✅ **Single item test creates JIRA issue successfully**  
✅ **No 403/401/404 errors**  
✅ **API calls return expected data**  

---

**Next Steps:** Set your JIRA_EMAIL and run diagnostics again! 🚀</content>
<parameter name="filePath">/home/ryan/repos/PAWS360ProjectPlan/JIRA_AUTH_TROUBLESHOOTING.md