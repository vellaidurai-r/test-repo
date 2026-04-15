# ⚙️ Elastic IP Setup - Manual Steps

Your scripts are ready! Follow these steps to get your static IP:

## Step 1: Add IAM Permissions to github-deploy-user

You need to do this in the AWS Console with an admin account (or IAM-authorized user).

### Option A: Using AWS Console (Easiest)

1. Go to **https://console.aws.amazon.com/iam/home#/users**
2. Find and click **github-deploy-user**
3. Click **Add inline policy** (or **Add permissions**)
4. Click **JSON** tab
5. Replace the content with this:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ElasticIPManagement",
      "Effect": "Allow",
      "Action": [
        "ec2:AllocateAddress",
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
        "ec2:DescribeAddresses",
        "ec2:ReleaseAddress"
      ],
      "Resource": "*"
    },
    {
      "Sid": "NetworkInterfaceAccess",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeNetworkInterfaceAttribute"
      ],
      "Resource": "*"
    }
  ]
}
```

6. Click **Review policy**
7. Name it: **ElasticIPManagement**
8. Click **Create policy**

### Option B: Using AWS CLI (If you have admin account)

If you have an admin AWS account configured locally:

```bash
aws iam put-user-policy --user-name github-deploy-user --policy-name ElasticIPManagement --policy-document file:///Users/white/Tech/ci-cd/hello-world-node/elastic-ip-policy.json
```

---

## Step 2: Allocate & Associate Elastic IP

Once the IAM permissions are added, run:

```bash
./setup-elastic-ip.sh
```

This will:
- Allocate a new Elastic IP
- Associate it with your ECS task
- Save the IP to `.elastic-ip`

**Expected output:**
```
✅ Elastic IP allocated: 13.211.XXX.XXX
✅ Found network interface: eni-0987654321fedcba0
✅ Elastic IP associated!

🎉 Your static IP is ready!
Public IP: 13.211.XXX.XXX
Access your app at: http://13.211.XXX.XXX:3000/
```

---

## Step 3: Test It Works

```bash
# Get your new static IP
cat .elastic-ip

# Test your app
curl http://$(cat .elastic-ip):3000/
```

You should see:
```
Hello World is awesome! - Node.js CI/CD Pipeline on AWS ECS
```

---

## What's Included in This Repository

✅ **setup-elastic-ip.sh** - Allocates and associates your Elastic IP (run once)
✅ **associate-elastic-ip.sh** - Re-associates after deployment (for automation)
✅ **elastic-ip-policy.json** - IAM permissions needed
✅ **.elastic-ip** - Will be created with your static IP
✅ **.elastic-ip-allocation-id** - Will be created with the allocation ID

---

## Next Deployments

After you set this up, every time you deploy:

```bash
git add app.js
git commit -m "Update app"
git push
# GitHub Actions automatically deploys
# Your app is at the SAME IP address ✅
```

---

## Troubleshooting

### "No running tasks found"
Your ECS task may not be running yet. Wait 30 seconds and try again:
```bash
./setup-elastic-ip.sh
```

### Permission Denied Error
Make sure you added the IAM policy in Step 1 and wait a minute for AWS to propagate it.

### Script not executable
```bash
chmod +x setup-elastic-ip.sh associate-elastic-ip.sh
```

---

## Important Notes

- ⏰ **Elastic IP allocation takes 1-2 minutes** - be patient
- 💾 **Don't delete `.elastic-ip-allocation-id` file** - needed for re-association
- 📌 **Only one Elastic IP per task** - we handle re-association automatically
- 💰 **Free while associated** with your task, $0.005/hour if left unassociated

---

## Ready? Start with Step 1 above! 🚀
