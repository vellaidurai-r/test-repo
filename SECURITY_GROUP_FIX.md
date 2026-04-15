# 🔧 AWS Security Group Fix - Complete Solution

## Problem Summary
- ✅ Local app working on `http://0.0.0.0:3000/`
- ✅ GitHub Actions pipeline working
- ✅ Docker image built and deployed
- ❌ AWS public IP not accessible on port 3000

## Root Cause
**Security Group is blocking port 3000 inbound traffic**

---

## 🔐 SOLUTION: Add Inbound Rule to Security Group

### Step-by-Step Fix

#### **Step 1: Go to AWS Console**
```
https://console.aws.amazon.com/
```

#### **Step 2: Open EC2 Dashboard**
1. Search for **"EC2"** in the search bar
2. Click **EC2** from results
3. In left sidebar, click **Security Groups**

#### **Step 3: Find Your Security Group**
1. You'll see a list of security groups
2. Look for the one used by your ECS task
3. Common names: `node-app-sg`, `default`, or a generated name
4. **Tip:** Go back to ECS task details to confirm which security group it uses
   - ECS → Clusters → `my-node-api-cluster`
   - Services → `node-app-service`
   - Click running task
   - Look for **Security groups** → Note the ID/Name

#### **Step 4: Click on Your Security Group**
Click the security group ID to open it

#### **Step 5: Go to Inbound Rules**
1. Click **Inbound rules** tab
2. You should see the current rules
3. **Look for:**
   - Port 3000, or
   - All ports, or
   - Nothing (empty)

#### **Step 6: Add Port 3000 Rule**

**If port 3000 is NOT there, click "Edit inbound rules"**

**Then click "Add rule":**

| Field | Value |
|-------|-------|
| Type | Custom TCP |
| Protocol | TCP |
| Port range | 3000 |
| Source | Custom → `0.0.0.0/0` |
| Description | Node.js App |

**Example:**
```
Type: Custom TCP
Protocol: TCP
Port range: 3000
Source: 0.0.0.0/0 (allows from anywhere)
Description: Node.js App
```

#### **Step 7: Save**
Click **"Save inbound rules"** button

#### **Step 8: Wait**
Wait 30-60 seconds for rule to take effect

---

## ✅ Verify the Fix

### In AWS Console:
1. **Inbound rules** should now show:
   ```
   Type          Protocol  Port Range  Source
   Custom TCP    TCP       3000        0.0.0.0/0
   ```

### Test from your Mac:
```bash
curl http://13.55.64.76:3000/
```

**Expected response:**
```
Hello World! - Node.js CI/CD Pipeline on AWS ECS
```

### Test in Browser:
Open: `http://13.55.64.76:3000/`

You should see: **Hello World! - Node.js CI/CD Pipeline on AWS ECS** ✅

---

## 📋 Alternative: Outbound Rules Check

Also verify **Outbound rules** (same security group):

1. Click **Outbound rules** tab
2. **You should see:**
   ```
   Type          Protocol  Port Range  Destination
   All traffic   All       All         0.0.0.0/0
   ```

**If this is missing:**
1. Click "Edit outbound rules"
2. Add:
   - Type: `All traffic`
   - Protocol: `All`
   - Port range: `All`
   - Destination: `0.0.0.0/0`
3. Save

---

## 🔍 If Still Not Working

### Check 1: Security Group Actually Attached to Task

1. **ECS** → **Clusters** → **`my-node-api-cluster`**
2. **Services** → **`node-app-service`**
3. Click the **running task**
4. Look for **Security groups** section
5. Confirm the security group ID matches the one you edited

**If not matching:**
- The task is using a different security group
- Find and edit THAT security group instead

### Check 2: Task Still Running

1. **Task Status** should be: **RUNNING** ✅
2. **Container Status** should be: **RUNNING** ✅
3. **Exit Code** should be: empty or 0 (not crashed)

**If not running:**
- Check logs for errors
- Fix the error in code
- Push to GitHub to redeploy

### Check 3: Public IP Still Valid

1. Look at task details
2. Confirm **Public IP** is: **13.55.64.76** (or your IP)
3. If changed, use the NEW IP to test

### Check 4: Subnet Has Internet Gateway

1. **VPC** → **Subnets**
2. Find subnet your task uses
3. Click it → **Route table** tab
4. **You should see:**
   ```
   Destination    Target
   0.0.0.0/0      igw-xxxxxxxx (Internet Gateway)
   ```

**If missing:**
- Your subnet not configured for internet access
- Need to add route or recreate service

---

## ⚡ Quick Fix Commands (If AWS CLI Available)

```bash
# Replace with your security group ID
SG_ID="sg-xxxxxxxxxx"
REGION="ap-southeast-2"

# Add inbound rule for port 3000
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 3000 \
  --cidr 0.0.0.0/0 \
  --region $REGION

echo "✅ Port 3000 rule added!"
```

---

## 📸 Visual Guide

### Before (Blocked)
```
Security Group Rules:
┌─────────────────────────────────┐
│ Inbound Rules:                  │
│ (empty - nothing allowed)        │
├─────────────────────────────────┤
│ Result: ❌ Port 3000 BLOCKED     │
└─────────────────────────────────┘
```

### After (Fixed)
```
Security Group Rules:
┌──────────────────────────────────────┐
│ Inbound Rules:                       │
│ Type: Custom TCP                     │
│ Protocol: TCP                        │
│ Port: 3000                           │
│ Source: 0.0.0.0/0                    │
├──────────────────────────────────────┤
│ Result: ✅ Port 3000 ALLOWED         │
└──────────────────────────────────────┘
```

---

## 🎯 Expected Final Result

### Local Machine ✅
```
$ curl http://0.0.0.0:3000/
Hello World! - Node.js CI/CD Pipeline on AWS ECS
```

### AWS Public IP ✅
```
$ curl http://13.55.64.76:3000/
Hello World! - Node.js CI/CD Pipeline on AWS ECS
```

### Browser ✅
```
Visit: http://13.55.64.76:3000/
See: "Hello World! - Node.js CI/CD Pipeline on AWS ECS"
```

---

## 📝 Summary

| Step | Action | Status |
|------|--------|--------|
| 1 | Go to EC2 Security Groups | ⏳ |
| 2 | Find your security group | ⏳ |
| 3 | Click Edit inbound rules | ⏳ |
| 4 | Add rule: TCP port 3000 | ⏳ |
| 5 | Save | ⏳ |
| 6 | Wait 30-60 seconds | ⏳ |
| 7 | Test: `curl http://13.55.64.76:3000/` | ⏳ |

---

## 🚨 Still Not Working?

**Provide these details:**

1. **Security Group Inbound Rules** - What rules are listed? (screenshot)
2. **Security Group ID** - What's the ID? (starts with `sg-`)
3. **Task Status** - RUNNING? Container RUNNING?
4. **Public IP** - Still `13.55.64.76`?
5. **Task Logs** - Any error messages?
6. **Recent GitHub Actions** - All green? ✅
7. **ECR Image** - Image timestamp (recent?)

---

## ✨ Success Indicators

Once fixed, you'll see:

✅ Security Group rule shows port 3000
✅ Can reach `http://13.55.64.76:3000/`
✅ See "Hello World!" message
✅ App responds from anywhere
✅ CI/CD pipeline continues to work

**Your setup is almost there! Just need to open port 3000 in security group.** 🚀
