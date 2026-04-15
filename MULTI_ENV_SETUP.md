# 🚀 Multi-Environment CI/CD Pipeline Setup

This guide explains how to set up and manage Development, Staging, and Production environments with automatic CI/CD deployment.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Repository                         │
│  ┌──────────────┬──────────────┬──────────────────────────┐ │
│  │   develop    │   staging    │        main              │ │
│  │  (DEV)       │  (STAGING)   │     (PRODUCTION)         │ │
│  └──────────────┴──────────────┴──────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
         ↓               ↓                    ↓
    GitHub Actions   GitHub Actions      GitHub Actions
         ↓               ↓                    ↓
    ┌─────────┐  ┌─────────────┐  ┌──────────────────┐
    │ DEV ENV │  │ STAGING ENV │  │ PRODUCTION ENV   │
    │ ECS     │  │ ECS         │  │ ECS              │
    │ ECR     │  │ ECR         │  │ ECR              │
    └─────────┘  └─────────────┘  └──────────────────┘
```

## Branch Strategy

| Branch | Environment | Purpose | Deploy On |
|--------|------------|---------|-----------|
| `develop` | **Development** | Feature development & testing | Every push |
| `staging` | **Staging** | Pre-production testing | Every push |
| `main` | **Production** | Live application | Every push (careful!) |

## Setup Steps

### Step 1: Create Git Branches

```bash
# From main branch
git checkout -b develop
git push -u origin develop

git checkout -b staging
git push -u origin staging

# You're already on main
```

### Step 2: Create AWS Resources for Each Environment

You need to create separate AWS resources for each environment:

#### Development Environment
```bash
# ECS Cluster
aws ecs create-cluster --cluster-name my-node-api-cluster-dev --region ap-southeast-2

# ECR Repository
aws ecr create-repository --repository-name backend-api-dev --region ap-southeast-2

# CloudWatch Log Group
aws logs create-log-group --log-group-name /ecs/node-app-task-dev --region ap-southeast-2
```

#### Staging Environment
```bash
# ECS Cluster
aws ecs create-cluster --cluster-name my-node-api-cluster-staging --region ap-southeast-2

# ECR Repository
aws ecr create-repository --repository-name backend-api-staging --region ap-southeast-2

# CloudWatch Log Group
aws logs create-log-group --log-group-name /ecs/node-app-task-staging --region ap-southeast-2
```

#### Production Environment
```bash
# ECS Cluster
aws ecs create-cluster --cluster-name my-node-api-cluster-prod --region ap-southeast-2

# ECR Repository
aws ecr create-repository --repository-name backend-api-prod --region ap-southeast-2

# CloudWatch Log Group
aws logs create-log-group --log-group-name /ecs/node-app-task-prod --region ap-southeast-2
```

### Step 3: Create ECS Services

For each environment, create an ECS service using the task definition:

**Development:**
```bash
aws ecs create-service \
  --cluster my-node-api-cluster-dev \
  --service-name node-app-service-dev \
  --task-definition node-app-task-dev \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-0e78938ff89580027],securityGroups=[sg-0a7e12ada81af1163],assignPublicIp=ENABLED}" \
  --region ap-southeast-2
```

Replace `subnet-0e78938ff89580027` and `sg-0a7e12ada81af1163` with your actual subnet and security group IDs.

### Step 4: GitHub Environments (Optional but Recommended)

Set up GitHub environments for approval gates on production:

1. Go to **Settings** → **Environments**
2. Click **New environment**
3. Name it: `production`
4. Add required reviewers
5. Add deployment branches: `refs/heads/main`

## How It Works

### Development Deployment
```bash
# Make changes on develop branch
git checkout develop
# ... make changes ...
git add .
git commit -m "Add new feature"
git push origin develop

# GitHub Actions automatically:
# 1. Builds Docker image
# 2. Pushes to backend-api-dev ECR
# 3. Deploys to development ECS cluster
# 4. Builds and tests on every push
```

### Staging Deployment
```bash
# Create pull request from develop to staging
git checkout staging
git pull origin develop
git push origin staging

# Workflow deploys to staging automatically
# Good for final testing before production
```

### Production Deployment
```bash
# Create pull request from staging to main
git checkout main
git pull origin staging
git push origin main

# WARNING: This automatically deploys to production!
# Use GitHub environment protection rules for approval
```

## Workflow Features

✅ **Automatic Testing**
- Installs dependencies
- Runs linter (if configured)
- Runs tests (if configured)
- Only deploys if tests pass

✅ **Dynamic Environment Detection**
- Automatically detects which branch pushed
- Uses correct ECR repository
- Uses correct ECS cluster and service
- Uses correct CloudWatch log group

✅ **Image Tagging**
- Tags with commit SHA for easy identification
- Also pushes `latest` tag
- Can rollback by deploying older commit SHA

✅ **Service Stability Check**
- Waits for ECS service to reach stable state
- Prevents concurrent deployments
- Ensures task is running before considering successful

## Getting Public IPs for Each Environment

Use the provided IP lookup scripts:

```bash
# Development
aws ecs list-tasks --cluster my-node-api-cluster-dev --region ap-southeast-2 --query 'taskArns[0]' --output text | xargs -I {} aws ecs describe-tasks --cluster my-node-api-cluster-dev --tasks {} --region ap-southeast-2 --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text | xargs -I {} aws ec2 describe-network-interfaces --network-interface-ids {} --region ap-southeast-2 --query 'NetworkInterfaces[0].Association.PublicIp' --output text

# Staging
aws ecs list-tasks --cluster my-node-api-cluster-staging --region ap-southeast-2 --query 'taskArns[0]' --output text | xargs -I {} aws ecs describe-tasks --cluster my-node-api-cluster-staging --tasks {} --region ap-southeast-2 --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text | xargs -I {} aws ec2 describe-network-interfaces --network-interface-ids {} --region ap-southeast-2 --query 'NetworkInterfaces[0].Association.PublicIp' --output text

# Production
aws ecs list-tasks --cluster my-node-api-cluster-prod --region ap-southeast-2 --query 'taskArns[0]' --output text | xargs -I {} aws ecs describe-tasks --cluster my-node-api-cluster-prod --tasks {} --region ap-southeast-2 --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text | xargs -I {} aws ec2 describe-network-interfaces --network-interface-ids {} --region ap-southeast-2 --query 'NetworkInterfaces[0].Association.PublicIp' --output text
```

Or create separate scripts for each environment.

## CloudWatch Logs

View logs for each environment:

```bash
# Development logs
aws logs tail /ecs/node-app-task-dev --follow --region ap-southeast-2

# Staging logs
aws logs tail /ecs/node-app-task-staging --follow --region ap-southeast-2

# Production logs
aws logs tail /ecs/node-app-task-prod --follow --region ap-southeast-2
```

## Deploying Specific Changes to Each Environment

### Deploy to Dev Only
```bash
git checkout develop
git add app.js
git commit -m "Test feature"
git push origin develop
# Deploys only to development
```

### Deploy to Staging Only
```bash
git checkout staging
git merge develop  # or cherry-pick specific commits
git push origin staging
# Deploys only to staging
```

### Deploy to Production
```bash
git checkout main
git merge staging
git push origin main
# Deploys only to production
# (Use with caution! Consider adding approval gates)
```

## Rollback to Previous Version

If something goes wrong in production:

```bash
# Find the previous working commit
git log --oneline | head -5

# Revert to that commit
git revert <commit-sha>
git push origin main

# Or force push previous version (use carefully!)
git reset --hard <commit-sha>
git push -f origin main
```

## Environment Variables

You can set environment-specific variables in the task definition:

```json
"environment": [
  {
    "name": "ENVIRONMENT",
    "value": "production"
  },
  {
    "name": "LOG_LEVEL",
    "value": "error"
  },
  {
    "name": "API_TIMEOUT",
    "value": "30000"
  }
]
```

## Secrets Management (Future Enhancement)

For sensitive data, use AWS Secrets Manager:

```json
"secrets": [
  {
    "name": "DATABASE_URL",
    "valueFrom": "arn:aws:secretsmanager:ap-southeast-2:497162053399:secret:prod/db-url"
  }
]
```

## Monitoring & Alerts (Optional)

Set up CloudWatch alarms:

```bash
# High CPU usage alert
aws cloudwatch put-metric-alarm \
  --alarm-name prod-high-cpu \
  --alarm-description "Alert if CPU > 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold
```

## Troubleshooting

### "Service not stabilizing"
- Check ECS task logs in CloudWatch
- Verify app is listening on port 3000
- Check security group allows inbound traffic

### "ECR repository not found"
- Verify ECR repo exists for that environment
- Check repository name matches workflow configuration

### "Task definition registration failed"
- Verify image URI is correct
- Check task definition JSON syntax
- Ensure IAM permissions allow ecs:RegisterTaskDefinition

## Next Steps

1. ✅ Create Git branches (develop, staging)
2. ✅ Create AWS resources for each environment
3. ✅ Create ECS services for each environment
4. ✅ Push code to test workflow
5. ✅ Monitor deployments in GitHub Actions
6. ✅ Set up GitHub environment approvals (optional)
7. ✅ Configure CloudWatch log viewing
8. ✅ Document environment-specific configurations

---

**Questions?** Check the GitHub Actions workflow file: `.github/workflows/multi-env-cicd.yml`
