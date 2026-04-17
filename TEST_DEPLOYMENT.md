# 🚀 Testing Your CI/CD Deployment

## What Just Happened

✅ You pushed to the `develop` branch with a test change
✅ GitHub Actions should now be building and deploying to **Development** environment

---

## 📊 Monitor the Deployment

### Step 1: Watch GitHub Actions

Go to: **https://github.com/vellaidurai-r/test-repo/actions**

You should see:
1. A new workflow run starting
2. Status: "Build and Test" → "Deploy"
3. Look for job: `multi-env-cicd`

#### What You'll See:
```
multi-env-cicd workflow
├─ determine-environment ✅
├─ build-and-test ⏳ (Building...)
└─ deploy ⏳ (Deploying...)
```

---

### Step 2: Check CloudWatch Logs

While it's deploying, watch the logs in real-time:

```bash
# Watch development logs as they stream in
aws logs tail /ecs/node-app-task-dev --follow
```

You should see output like:
```
App listening at http://0.0.0.0:3000
```

---

### Step 3: Get the Development Public IP

```bash
# Get the current dev task
TASK=$(aws ecs list-tasks --cluster my-node-api-cluster-dev --region ap-southeast-2 --query 'taskArns[0]' --output text)

# Get its network interface
ENI=$(aws ecs describe-tasks --cluster my-node-api-cluster-dev --tasks $TASK --region ap-southeast-2 --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text)

# Get its public IP
aws ec2 describe-network-interfaces --network-interface-ids $ENI --region ap-southeast-2 --query 'NetworkInterfaces[0].Association.PublicIp' --output text
```

Example output: `13.210.244.139`

---

### Step 4: Test the Application

Once you have the IP, test it:

```bash
# Replace with your actual IP
curl http://13.210.244.139:3000/

# Expected output:
# ✅ CI/CD Pipeline Test - Environment: dev - Node.js on AWS ECS
```

---

## 📋 Expected Timeline

| Time | What Happens |
|------|--------------|
| T+0s | You push to develop |
| T+5s | GitHub Actions starts workflow |
| T+15s | Docker builds (download base image, install deps) |
| T+30s | Image pushed to ECR |
| T+40s | Task definition registered |
| T+50s | ECS service updated |
| T+60s | Old task stops, new task starts |
| T+90s | New task fully running & healthy |

**Total time: ~2-3 minutes for full deployment**

---

## 🔍 Troubleshooting Deployment

### Workflow doesn't start
- ✅ Check branch is `develop`
- ✅ Check `main` branch has `.github/workflows/multi-env-cicd.yml`
- ✅ Check GitHub secrets are set (AWS credentials)

### Workflow fails at "Build"
- Check CloudWatch logs for syntax errors in app.js
- Run `npm ci` locally to test dependencies

### Workflow fails at "Deploy"
- Check CloudWatch logs for runtime errors
- Verify image was pushed to ECR correctly
- Check ECS service has capacity

### Task won't start (stuck in "PENDING")
- Check security group allows port 3000
- Check subnet is valid
- Check IAM role has correct permissions

---

## 📈 Monitor via AWS Console

### 1. Check ECS Service Status

```bash
aws ecs describe-services \
  --cluster my-node-api-cluster-dev \
  --services node-app-service-dev \
  --region ap-southeast-2 \
  --query 'services[0].[status,desiredCount,runningCount]' \
  --output text
```

Expected: `ACTIVE 1 1`

### 2. Check Task Status

```bash
aws ecs list-tasks \
  --cluster my-node-api-cluster-dev \
  --region ap-southeast-2 \
  --query 'taskArns[0]'
```

Then describe it:

```bash
aws ecs describe-tasks \
  --cluster my-node-api-cluster-dev \
  --tasks <TASK_ARN> \
  --region ap-southeast-2
```

Look for: `"lastStatus": "RUNNING"`

### 3. Check ECR Image

```bash
aws ecr describe-images \
  --repository-name backend-api-dev \
  --region ap-southeast-2 \
  --query 'imageDetails[0].[imageTags,imagePushedAt]'
```

---

## ✅ Verification Checklist

- [ ] GitHub Actions workflow started
- [ ] Workflow reached "Deploy" stage
- [ ] CloudWatch logs show "App listening"
- [ ] ECS task is RUNNING
- [ ] Public IP is assigned
- [ ] `curl http://IP:3000/` returns the new message
- [ ] Response includes "Environment: dev"

---

## 🎯 What to Check Next

### Staging Deployment

Once dev is working, test staging:

```bash
git checkout staging
git merge develop
git push origin staging
```

Then check: `aws logs tail /ecs/node-app-task-staging --follow`

### Production Deployment

```bash
git checkout main
git merge staging
git push origin main
```

Then check: `aws logs tail /ecs/node-app-task-prod --follow`

---

## 📊 Quick Dashboard Commands

Create a monitoring dashboard with these commands:

```bash
#!/bin/bash

echo "═══════════════════════════════════════════════════════════"
echo "📊 Multi-Environment Status Dashboard"
echo "═══════════════════════════════════════════════════════════"
echo ""

for ENV in dev staging prod; do
  echo "Environment: $ENV"
  CLUSTER="my-node-api-cluster-$ENV"
  SERVICE="node-app-service-$ENV"
  
  STATUS=$(aws ecs describe-services \
    --cluster $CLUSTER \
    --services $SERVICE \
    --region ap-southeast-2 \
    --query 'services[0].status' \
    --output text)
  
  RUNNING=$(aws ecs describe-services \
    --cluster $CLUSTER \
    --services $SERVICE \
    --region ap-southeast-2 \
    --query 'services[0].runningCount' \
    --output text)
  
  echo "  Status: $STATUS"
  echo "  Running: $RUNNING/1"
  echo ""
done
```

Save this as `check-status.sh` and run: `chmod +x check-status.sh && ./check-status.sh`

---

## 🎉 Success Indicators

You'll know the deployment worked when:

1. ✅ GitHub Actions shows "Deploy" job as successful (green checkmark)
2. ✅ CloudWatch logs show "App listening" message
3. ✅ `curl http://IP:3000/` shows: "✅ CI/CD Pipeline Test - Environment: dev"
4. ✅ ECS service shows 1 running task
5. ✅ Same message appears in all three environments (dev, staging, prod)

---

## 📝 Next Test Steps

### Test 1: Change the message again
```bash
# Edit app.js with new message
git add app.js
git commit -m "Test 2: Another deployment"
git push origin develop
# Watch it deploy automatically!
```

### Test 2: Promote to Staging
```bash
git checkout staging
git merge develop
git push origin staging
# Deployment to staging should start automatically
```

### Test 3: Production Deployment
```bash
git checkout main
git merge staging
git push origin main
# Deployment to production should start automatically
# Watch it carefully - this is production!
```

---

## 🚨 Rollback Test

If something goes wrong, test rolling back:

```bash
# Find the previous good commit
git log --oneline | head -5

# Revert to previous version
git revert <commit-sha>
git push origin develop

# Watch it automatically rollback!
```

---

## 📞 Helpful Commands

```bash
# View recent commits
git log --oneline -10

# Check which branch you're on
git branch

# View workflow files
ls -la .github/workflows/

# Check if all services are running
aws ecs list-services --cluster my-node-api-cluster-dev --region ap-southeast-2

# View task definitions
aws ecs list-task-definitions --region ap-southeast-2

# Get ECR image info
aws ecr describe-images --repository-name backend-api-dev --region ap-southeast-2
```

---

## 🎓 What You're Testing

Your test validates:
- ✅ Git push triggers workflow
- ✅ Workflow detects correct branch
- ✅ Docker image builds correctly
- ✅ Image pushes to correct ECR
- ✅ Task definition updates
- ✅ ECS service deploys
- ✅ App starts and listens
- ✅ Public IP is assigned
- ✅ App is accessible from internet

**If all of these work, your CI/CD pipeline is production-ready!** 🚀

---

**Commit pushed**: `494bcf5` - "Test: Update message to verify CI/CD deployment"

**Time to check**: Now! Go watch it deploy at GitHub Actions!
