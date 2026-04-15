# 🚀 Multi-Environment CI/CD - Quick Reference

## Setup Checklist

- [ ] Create Git branches (`develop`, `staging`)
- [ ] Run `./setup-multi-env.sh` to create AWS resources
- [ ] Create ECS Services for each environment
- [ ] Push code to test workflow

## Environment Overview

| Environment | Branch | Auto-Deploy | Purpose |
|-------------|--------|-------------|---------|
| **Development** | `develop` | ✅ Every push | Daily development & testing |
| **Staging** | `staging` | ✅ Every push | Pre-production validation |
| **Production** | `main` | ✅ Every push | Live application |

## Quick Start Commands

### 1. Create Branches
```bash
git checkout -b develop
git push -u origin develop

git checkout -b staging
git push -u origin staging
```

### 2. Create AWS Resources
```bash
./setup-multi-env.sh
```

### 3. Create ECS Services (Repeat for dev, staging, prod)
```bash
# For each environment:
aws ecs create-service \
  --cluster my-node-api-cluster-dev \
  --service-name node-app-service-dev \
  --task-definition node-app-task-dev \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[SUBNET_ID],securityGroups=[SG_ID],assignPublicIp=ENABLED}" \
  --region ap-southeast-2
```

Replace `SUBNET_ID` and `SG_ID` with your values.

## Common Workflows

### Add a Feature to Development
```bash
git checkout develop
git pull origin develop
git checkout -b feature/my-feature

# Make changes
git add .
git commit -m "Add feature"
git push origin feature/my-feature

# Create PR on GitHub: develop ← feature/my-feature
```

### Promote Development to Staging
```bash
# Create PR on GitHub: staging ← develop
# Once tests pass, merge
# Automatically deploys to staging!
```

### Deploy to Production
```bash
# Create PR on GitHub: main ← staging
# Request review (optional: set up approval gates)
# Once tests pass, merge
# Automatically deploys to production!
```

## Check Deployment Status

```bash
# Watch GitHub Actions
# Go to repository → Actions tab

# Or check CloudWatch logs
aws logs tail /ecs/node-app-task-dev --follow
aws logs tail /ecs/node-app-task-staging --follow
aws logs tail /ecs/node-app-task-prod --follow
```

## Get Public IPs

```bash
# Development
aws ecs list-tasks --cluster my-node-api-cluster-dev --region ap-southeast-2

# Staging
aws ecs list-tasks --cluster my-node-api-cluster-staging --region ap-southeast-2

# Production
aws ecs list-tasks --cluster my-node-api-cluster-prod --region ap-southeast-2
```

## Emergency Rollback

```bash
# Revert to previous version
git log --oneline | head -5
git revert -m 1 <commit-sha>
git push origin main

# GitHub Actions will immediately start rollback deployment
```

## Files Involved

| File | Purpose |
|------|---------|
| `.github/workflows/multi-env-cicd.yml` | CI/CD workflow configuration |
| `ecs-task-def-template.json` | Task definition template |
| `MULTI_ENV_SETUP.md` | Detailed setup guide |
| `GIT_BRANCH_SETUP.md` | Git branching strategy |
| `setup-multi-env.sh` | AWS resource creation script |

## Environment-Specific URLs

Once deployed:

```
Development:  http://DEV_IP:3000/
Staging:      http://STAGING_IP:3000/
Production:   http://PROD_IP:3000/
```

## Key Concepts

✅ **Branch Strategy**: develop → staging → main
✅ **Auto-Deploy**: Every push triggers CI/CD
✅ **Separate Infrastructure**: Each env has own ECR, cluster, service
✅ **Atomic Deployments**: New Docker image per commit
✅ **Easy Rollback**: Just revert to previous commit
✅ **Environment Variables**: App knows which env it's running in

## Next Steps

1. ✅ Create branches
2. ✅ Run setup script
3. ✅ Create ECS services
4. ✅ Make a test push to develop
5. ✅ Monitor GitHub Actions
6. ✅ Verify app deployed
7. ✅ Promote through environments

---

**Full docs:** See `MULTI_ENV_SETUP.md` and `GIT_BRANCH_SETUP.md`

**Issues?** Check `.github/workflows/multi-env-cicd.yml` for workflow logic
