# 🎯 IP Address Management Guide

## Important: Public IP Changes After Each Deployment

### Why?

When you push code:
1. GitHub Actions builds new Docker image
2. Image is pushed to ECR
3. ECS **stops old container** → **Old IP released**
4. ECS **starts new container** → **New IP assigned**

This is normal AWS Fargate behavior!

---

## ✅ Your Current Setup

| Component | Status |
|-----------|--------|
| Application | ✅ Working |
| CI/CD Pipeline | ✅ Automatic |
| Public Access | ✅ Available (IP changes) |
| Updated Code | ✅ "Hello World is awesome!" |

---

## 🔍 Getting the Current IP

### Method 1: Use the Script (Easiest)

```bash
cd /Users/white/Tech/ci-cd/hello-world-node
./get-ip.sh
```

**Output:**
```
✅ Current Public IP: 13.210.244.139

📍 Access your app at:
   http://13.210.244.139:3000/
```

### Method 2: Manual AWS CLI Command

```bash
# Get task ARN
TASK=$(aws ecs list-tasks --cluster my-node-api-cluster --region ap-southeast-2 --query 'taskArns[0]' --output text)

# Get ENI
ENI=$(aws ecs describe-tasks --cluster my-node-api-cluster --tasks $TASK --region ap-southeast-2 --query 'tasks[0].attachments[0].details' --output text | grep networkInterfaceId | awk '{print $2}')

# Get public IP
aws ec2 describe-network-interfaces --network-interface-ids $ENI --region ap-southeast-2 --query 'NetworkInterfaces[0].Association.PublicIp' --output text
```

### Method 3: AWS Console

1. Go to **AWS Console** → **ECS**
2. **Clusters** → **`my-node-api-cluster`**
3. **Services** → **`node-app-service`**
4. Click running **Task**
5. Look for **Attachments** → Network interface → Public IP

---

## 🔄 Workflow

### Development Cycle

```
1. Make code change locally
   ↓
2. Test on localhost:3000
   ↓
3. Push to GitHub
   git push origin main
   ↓
4. GitHub Actions triggers
   ↓
5. Docker image built & pushed to ECR
   ↓
6. ECS service updates
   ↓
7. New task starts with NEW PUBLIC IP
   ↓
8. Get new IP with:
   ./get-ip.sh
   ↓
9. Test at http://<new-ip>:3000/
   ↓
10. Repeat!
```

---

## 📝 Example: Full Deployment

### Step 1: Make a Code Change

Edit `app.js`:
```javascript
res.send('My new message!');
```

### Step 2: Test Locally

```bash
npm start
# Test: http://localhost:3000/
```

### Step 3: Commit and Push

```bash
git add app.js
git commit -m "Update: New message"
git push origin main
```

### Step 4: Wait for Deployment

Go to GitHub → Actions → Watch the workflow

(Takes about 3-5 minutes)

### Step 5: Get the New IP

```bash
./get-ip.sh
```

Output:
```
✅ Current Public IP: 13.210.244.139
📍 Access your app at:
   http://13.210.244.139:3000/
```

### Step 6: Test on AWS

```bash
curl http://13.210.244.139:3000/
# Should show: "My new message!"
```

---

## ⭐ Better Alternative: Use Elastic IP or Load Balancer

If you want a **static IP that doesn't change**, use one of these:

### Option 1: Elastic IP (Simple)

**Pros:** Same IP always
**Cons:** Small additional cost

```bash
# Create elastic IP
aws ec2 allocate-address --domain vpc --region ap-southeast-2
```

### Option 2: Application Load Balancer (Recommended)

**Pros:** Professional, scalable, DNS-based
**Cons:** More complex setup

Instead of: `http://13.210.244.139:3000/`
You'd have: `http://my-app.example.com:3000/`

DNS name never changes even if IP changes!

---

## 🛠️ Helpful Scripts

### Get IP Quickly
```bash
./get-ip.sh
```

### Test App After Deployment
```bash
IP=$(./get-ip.sh | grep "✅" | awk '{print $NF}')
curl http://$IP:3000/
```

### Monitor Logs
```bash
aws logs tail /ecs/node-app-task --follow --region ap-southeast-2
```

---

## 📋 Checklist After Each Push

- [ ] Code pushed to GitHub
- [ ] GitHub Actions runs (check Actions tab)
- [ ] Workflow completes (green ✅)
- [ ] Run `./get-ip.sh` to get new IP
- [ ] Test with new IP: `curl http://<IP>:3000/`
- [ ] See your latest changes

---

## ✨ Your Setup is Production-Ready!

You have:
- ✅ Automated CI/CD pipeline
- ✅ Docker containerization
- ✅ AWS ECS deployment
- ✅ Public access
- ✅ Quick IP lookup tool

**The only "limitation" is that IP changes with each deployment** - which is normal for Fargate and easily handled with the `get-ip.sh` script!

---

## 🚀 Next Steps (Optional)

1. Set up Elastic IP for static IP
2. Configure custom domain
3. Add Load Balancer
4. Set up monitoring & alerts
5. Add auto-scaling
6. Add database

But for now, **your app is working perfectly!** 🎉
