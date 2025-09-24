# PAWS360 GitHub Integration Setup Guide

## 🎯 Goal
Link JIRA project PGB to GitHub repository: https://github.com/ZackHawkins/PAWS360

## 📋 Manual Setup Steps

### Step 1: Configure GitHub Integration in JIRA
1. Go to JIRA Settings → Apps → DVCS accounts
2. Click "Link GitHub account"
3. Choose "GitHub Cloud" 
4. Authorize JIRA to access your GitHub account
5. Select the repository: `ZackHawkins/PAWS360`

### Step 2: Verify Integration
1. Check that commits appear in JIRA issues
2. Verify branch names show in development panel
3. Confirm pull requests link to JIRA tickets

## 🔧 Alternative: Webhook Setup

If DVCS integration doesn't work:

1. Go to GitHub repository settings
2. Navigate to Webhooks
3. Add webhook with URL: `https://paw360.atlassian.net/rest/bitbucket/1.0/repository/{repo_id}/sync`
4. Set content type to `application/json`
5. Select events: Push, Pull Request, Issue Comment

## ✅ Expected Results
- ✅ Commits automatically link to JIRA issues
- ✅ Branch names appear in JIRA issue development panel  
- ✅ Pull requests show in JIRA issue links
- ✅ Smart commits work (e.g., `git commit -m "PGB-123 #done"`)

## 🚨 Troubleshooting
- Ensure repository is public or JIRA has access
- Check webhook delivery logs in GitHub
- Verify JIRA user has repository access
