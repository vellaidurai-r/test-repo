# Git Branch Setup for Multi-Environment CI/CD

This document explains how to set up Git branches for development, staging, and production.

## Branch Structure

```
main (production)
  ↑
  └── pull request from staging
  
staging (pre-production)
  ↑
  └── pull request from develop

develop (development)
  ↑
  └── feature branches
```

## Creating Branches

### Step 1: Create `develop` branch

```bash
# Make sure you're on main
git checkout main
git pull origin main

# Create and push develop branch
git checkout -b develop
git push -u origin develop

# You can now see develop branch on GitHub
```

### Step 2: Create `staging` branch

```bash
# Create staging branch from main
git checkout main
git checkout -b staging
git push -u origin staging
```

### Verify Branches

```bash
git branch -a
# Output:
# * main
#   remotes/origin/develop
#   remotes/origin/main
#   remotes/origin/staging
```

## Branch Protection Rules (Recommended)

Set up branch protection on GitHub to prevent accidents:

### For `main` (Production)

1. Go to **Settings** → **Branches**
2. Click **Add rule** 
3. Branch name pattern: `main`
4. Enable:
   - ✅ Require pull request reviews before merging
   - ✅ Dismiss stale pull request approvals when new commits are pushed
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
5. Click **Create**

### For `staging` (Pre-Production)

1. Go to **Settings** → **Branches**
2. Click **Add rule**
3. Branch name pattern: `staging`
4. Enable:
   - ✅ Require status checks to pass before merging
5. Click **Create**

### For `develop` (Development - Optional)

Generally, develop branch doesn't need strict protection since it's for active development.

## Workflow: Adding New Features

### Create Feature Branch

```bash
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/your-feature-name

# Make changes
# ... edit files ...

git add .
git commit -m "Add your feature description"
git push -u origin feature/your-feature-name
```

### Create Pull Request

1. Go to your GitHub repository
2. Click "Compare & pull request"
3. Ensure:
   - Base: `develop`
   - Compare: `feature/your-feature-name`
4. Add description
5. Click "Create pull request"

### Merge to Develop

Once tests pass and review is approved:

1. Click "Merge pull request"
2. Choose merge strategy: "Create a merge commit"
3. Delete the feature branch

---

## Workflow: Promoting to Staging

When ready to test in staging environment:

```bash
# Update develop locally
git checkout develop
git pull origin develop

# Create pull request on GitHub:
# - Base: staging
# - Compare: develop

# After review and CI/CD passes:
# - Merge with "Create a merge commit"
```

---

## Workflow: Deploying to Production

When ready to release:

```bash
# Update staging locally
git checkout staging
git pull origin staging

# Create pull request on GitHub:
# - Base: main
# - Compare: staging

# After review and CI/CD passes:
# - Merge with "Create a merge commit"
# - GitHub Actions automatically deploys!
```

---

## Quick Commit Flow Example

```bash
# 1. Feature development on develop
git checkout develop
git pull origin develop
git checkout -b feature/add-logging

# Make changes
echo "console.log('Debug info')" >> app.js
git add app.js
git commit -m "Add debug logging"
git push origin feature/add-logging

# 2. On GitHub: Create PR develop ← feature/add-logging
# 3. Review and merge when tests pass

# 4. Promote to staging
git checkout staging
git pull origin staging
# On GitHub: Create PR staging ← develop
# Merge when ready

# 5. Promote to production
git checkout main
git pull origin main
# On GitHub: Create PR main ← staging
# Merge when ready
# GitHub Actions auto-deploys!
```

## Syncing Branches

After merging a feature to develop, sync other branches:

```bash
# Sync staging with develop
git checkout staging
git pull origin staging
git merge develop
git push origin staging

# Sync main with staging (use PR instead for production)
git checkout main
git pull origin main
git merge staging
git push origin main
```

## Rolling Back a Release

If something goes wrong:

```bash
# Option 1: Revert the merge commit
git log --oneline | head -5
git revert -m 1 <commit-sha>
git push origin main
# Creates a new commit that undoes the changes

# Option 2: Reset to previous version (use carefully!)
git reset --hard <commit-sha>
git push -f origin main
# Forces branch history back
```

## Common Git Commands for This Workflow

```bash
# See all branches
git branch -a

# Switch branch
git checkout develop

# Create new branch
git checkout -b feature/name

# View changes
git status
git diff

# Stage and commit
git add .
git commit -m "message"

# Push changes
git push origin feature/name

# Update current branch
git pull origin develop

# Delete local branch
git branch -d feature/name

# Delete remote branch
git push origin --delete feature/name
```

## Environment-to-Branch Mapping

| Git Branch | AWS Environment | Auto-Deploy | Use Case |
|------------|-----------------|-------------|----------|
| `develop` | Development | ✅ Every push | Feature development & testing |
| `staging` | Staging | ✅ Every push | Pre-production testing |
| `main` | Production | ✅ Every push | Live application (use PRs for safety) |

---

**Pro Tip:** Always use pull requests, even for develop branch. It enables:
- Code review
- CI/CD status checks
- Audit trail
- Safe merging

See `MULTI_ENV_SETUP.md` for AWS infrastructure setup.
