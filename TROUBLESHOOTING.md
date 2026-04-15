# 🔧 Troubleshooting Guide - Connection Issues

## Issue: Cannot Connect to Application on Port 3000

Your app should be running, but connection times out. Follow these steps:

---

## Step 1: Verify Task is Still Running

1. Go to **AWS Console** → **ECS** → **Clusters**
2. Click **`my-node-api-cluster`**
3. Click **Services** → **`node-app-service`**
4. **Check:**
   - Status: **ACTIVE** ✅
   - Desired count: **1**
   - Running count: **1**

If running count is **0**, the task crashed. Go to Step 3.

---

## Step 2: Check Container Status & Logs

1. Click on the **running task** (under Tasks tab)
2. **Look for:**
   - Task Status: **RUNNING** ✅
   - Container Name: `node-backend`
   - Container Last Status: **RUNNING** ✅

3. **Scroll down to LOGS section**
4. **You should see:**
   ```
   App listening at http://0.0.0.0:3000
   ```

**If you see error messages:**
- Note them and check troubleshooting section below

**If logs are empty:**
- Wait a few seconds and refresh
- Or check CloudWatch logs (next step)

---

## Step 3: Check CloudWatch Logs

1. Go to **AWS Console** → **CloudWatch** → **Log Groups**
2. Look for: **`/ecs/node-app-task`**
3. Click on it
4. **View recent log streams**
5. **Look for:**
   ```
   App listening at http://0.0.0.0:3000
   ```

**Errors might show:**
- `Cannot find module 'express'` → Dependencies issue
- `EADDRINUSE` → Port already in use
- `Module not found` → Missing files

---

## Step 4: Check Network Configuration

In the **Task Details** page:

1. **Scroll to Attachments section**
2. Look for **networkInterfaceId**: `eni-xxxxxxxxx`
3. **Verify it shows a Public IP**

If **no public IP**:
- The subnet might not have internet gateway
- Or `assignPublicIp` is not enabled

---

## Step 5: Check Security Group

1. Go to **EC2** → **Security Groups**
2. Find the security group attached to your task
3. **Inbound Rules tab:**
   - Look for Port **3000** or **All Traffic**
   - Source should be **0.0.0.0/0** (or your IP)

**If port 3000 is NOT listed:**
1. Click **Edit inbound rules**
2. Click **Add rule**
3. Set:
   - Type: **Custom TCP**
   - Port Range: **3000**
   - Source: **0.0.0.0/0**
4. Click **Save**
5. Wait 30 seconds and try again

---

## Step 6: Verify Image in ECR

1. Go to **AWS Console** → **ECR** → **Repositories**
2. Click **`backend-api`**
3. **You should see:**
   - Image tag: **latest**
   - Image status: **AVAILABLE**
   - Pushed at: Recent timestamp

If image is old:
- Your GitHub Actions workflow may have failed
- Check GitHub Actions → Actions tab for errors

---

## Step 7: Check GitHub Actions Workflow

1. Go to your GitHub repo
2. Click **Actions** tab
3. **Look at recent workflow runs:**
   - Should show commits you pushed
   - Status should be **✅ (green)** for success
   - Should show "All jobs successful"

**If workflow failed (red ❌):**
- Click on the failed run
- Scroll down to see error messages
- Common issues:
  - AWS credentials expired
  - IAM permissions missing
  - Docker build failed

---

## Quick Checklist

- [ ] Task Status: RUNNING
- [ ] Container Status: RUNNING
- [ ] Logs show: "App listening at http://0.0.0.0:3000"
- [ ] Security Group allows port 3000
- [ ] Task has a Public IP assigned
- [ ] Image in ECR is recent
- [ ] GitHub Actions workflow succeeded

---

## If Still Not Working

Provide the following information:

1. **Task Status from ECS console**
2. **Container Last Status**
3. **What the logs show** (copy the last few lines)
4. **Security Group inbound rules**
5. **The Public IP address**
6. **GitHub Actions workflow status** (success or failed?)

This will help identify the exact issue.

---

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Task crashed | Check logs, fix errors, push to GitHub |
| Port 3000 blocked | Add inbound rule to security group |
| No public IP | Enable `assignPublicIp` in ECS service |
| Image not updating | Check GitHub Actions workflow succeeded |
| Can't reach IP | Verify security group and public IP |
| Old image deployed | Re-run GitHub Actions workflow |

---

## Test Connection After Fix

Once everything is verified:

```bash
curl http://<public-ip>:3000/

# You should see:
# Hello World!
```

Or visit in browser: `http://<public-ip>:3000/`
