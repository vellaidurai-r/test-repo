# 🔍 Connection Checklist - Step by Step

## The Issue
Your GitHub Actions succeeds (Docker image built and deployed), but you can't access the app at `http://3.107.204.191:3000/`

**This is a Network/Security issue, NOT an application issue.**

---

## ✅ Checklist to Complete

### [ ] Step 1: Verify Task is Running

1. Go to **AWS Console** → **ECS**
2. Click **Clusters** → **`my-node-api-cluster`**
3. Click **Services** → **`node-app-service`**
4. Look at **Summary** section:
   - [ ] **Status**: `ACTIVE` (green)
   - [ ] **Desired Count**: `1`
   - [ ] **Running Count**: `1`

**If Running Count is 0:**
- Go to Tasks tab
- Check why task is not running
- Check CloudWatch logs for errors

---

### [ ] Step 2: Check Container Logs

1. Click on the **Task ID/ARN** under Tasks tab
2. Scroll down to **Logs** section
3. You should see logs like:
   ```
   App listening at http://0.0.0.0:3000
   ```

**If you don't see this:**
- [ ] Refresh the page
- [ ] Wait 10 seconds
- [ ] Look for any error messages

**If there are errors:**
- Fix the error in your code
- Commit and push to GitHub
- Wait for GitHub Actions to complete
- New deployment will auto-start

---

### [ ] Step 3: Get the Network Interface ID

Still in **Task Details** page:

1. Look for **Attachments** section
2. Find: **networkInterfaceId**
3. It looks like: `eni-0abc1234defgh5678`
4. **Copy this ID**

---

### [ ] Step 4: Verify Public IP Assignment

In the same **Task Details**:

1. Look for **Public IP** or **Elastic IP**
2. Should show: `3.107.204.191` (or similar)
3. If you **don't see a Public IP**:
   - This is the problem!
   - The subnet doesn't have public IP auto-assign enabled
   - Or there's no Internet Gateway
   - **Solution**: Update ECS service configuration

---

### [ ] Step 5: Check Security Group Rules

1. Go to **EC2 Dashboard** → **Security Groups**
2. Look for the security group name (note it from Task Details)
3. Click on it
4. Go to **Inbound rules** tab
5. **You should see one of:**
   - `Type: Custom TCP, Port: 3000, Source: 0.0.0.0/0`
   - `Type: All traffic, Source: 0.0.0.0/0`

**If you DON'T see port 3000 or All traffic:**

1. Click **Edit inbound rules**
2. Click **Add rule**
3. Set these values:
   - **Type**: Custom TCP
   - **Protocol**: TCP
   - **Port range**: 3000
   - **Source**: Custom (then type `0.0.0.0/0`)
   - **Description**: Node.js app
4. Click **Save**
5. **Wait 30-60 seconds** for rule to take effect

---

### [ ] Step 6: Check Outbound Rules (Same Security Group)

1. Click **Outbound rules** tab
2. **You should see:**
   - `All traffic | All | 0.0.0.0/0`

**If this is missing:**
- Add it with same steps as above
- Source → Destination: `0.0.0.0/0`

---

### [ ] Step 7: Verify Internet Gateway

The subnet must have an Internet Gateway:

1. Go to **VPC Dashboard** → **Internet Gateways**
2. Find one with status **Available**
3. Go to **VPC Dashboard** → **Subnets**
4. Find the subnet your task is using (from Task Details)
5. Click on it → **Route table**
6. **You should see:**
   - Destination: `0.0.0.0/0`
   - Target: `igw-xxxxxxxxx` (Internet Gateway ID)

**If this route is missing:**
- Add it manually or recreate the service

---

### [ ] Step 8: Verify Image in ECR

1. Go to **ECR** → **Repositories**
2. Click **`backend-api`**
3. **You should see:**
   - Image tag: **latest**
   - Image status: **AVAILABLE**
   - Pushed date: **Recent** (within last few minutes)

**If image is old:**
- GitHub Actions may have failed
- Check GitHub Actions logs for errors

---

### [ ] Step 9: Check GitHub Actions Status

1. Go to your GitHub repository
2. Click **Actions** tab
3. **Look at the latest run:**
   - [ ] Status: **Green checkmark** (✅ success)
   - [ ] Shows: "All jobs successful"

**If it's red (❌):**
- Click on the failed run
- Scroll down to see the error
- Fix and push again

---

### [ ] Step 10: Final Network Test

Once all above is configured:

1. Open terminal and run:
   ```bash
   curl http://3.107.204.191:3000/
   ```

2. **Expected response:**
   ```
   Hello World!
   ```

3. **Or open in browser:**
   ```
   http://3.107.204.191:3000/
   ```

---

## 🆘 If Still Not Working

**Provide these details:**

1. [ ] **Task Status**: What does it show?
2. [ ] **Container Logs**: What's the last line?
3. [ ] **Security Group Port 3000**: Is it added? (Yes/No)
4. [ ] **Public IP**: Does it have one? (Yes/No)
5. [ ] **GitHub Actions**: Success or Failed?
6. [ ] **New Public IP**: `3.107.204.191` or something else?

---

## 📋 Summary

| Component | Status | Where to Check |
|-----------|--------|-----------------|
| Task Running | ? | ECS → Service → Tasks |
| Container Running | ? | ECS → Task Details |
| Public IP Assigned | ? | ECS → Task Details → Attachments |
| Port 3000 Allowed | ? | EC2 → Security Groups → Inbound Rules |
| Internet Gateway | ? | VPC → Internet Gateways |
| Image in ECR | ? | ECR → Repositories → backend-api |
| GitHub Actions | ? | GitHub → Actions |

---

## 🎯 Next Step

**Go through each checkbox above** and let me know which ones pass ✅ and which ones fail ❌

This will help identify exactly what's blocking the connection!
