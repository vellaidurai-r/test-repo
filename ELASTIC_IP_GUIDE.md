# Elastic IP Setup Gui3. Click **Create inline policy**
4. Choose **JSON** tab
5. Copy the content from `elastic-ip-policy.json` in this repository
6. Name it: **elastic-ip-policy**
7. Click **Create policy**# Overview

This guide walks you through setting up an **Elastic IP** for your ECS Fargate application. An Elastic IP is a static public IP address that remains the same even when you redeploy your application.

## Why Elastic IP?

- ✅ **Static Address**: IP stays the same across deployments
- ✅ **No DNS Changes**: Always use the same URL
- ✅ **Easy Management**: Simple point-and-click or CLI setup
- ✅ **Cost**: Free while associated with running instance, charged when unassociated
- ✅ **Production Ready**: Industry standard for static IPs on AWS

## Setup Steps

### Step 1: Add IAM Permissions

Your GitHub Actions user needs permission to manage Elastic IPs. 

1. Go to **AWS Console** → **IAM** → **Users** → Select **github-deploy-user**
2. Click **Add permissions** → **Attach policies**
3. Click **Create inline policy**
4. Choose **JSON** tab
5. Copy the content from `elastic-ip-policy.json` in this repository
6. Name it: `ElasticIPManagement`
7. Click **Create policy**

**Or use AWS CLI:**

```bash
# First, save the policy
cat > /tmp/eip-policy.json << 'EOF'
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
EOF

# Then attach it
aws iam put-user-policy --user-name github-deploy-user --policy-name ElasticIPManagement --policy-document file:///tmp/eip-policy.json
```

### Step 2: Allocate and Associate Elastic IP

Run the setup script (requires the IAM permissions to be in place):

```bash
./setup-elastic-ip.sh
```

This script will:
1. Allocate a new Elastic IP
2. Find your current ECS task's network interface
3. Associate the Elastic IP with it
4. Save the IP to `.elastic-ip` file
5. Save the allocation ID to `.elastic-ip-allocation-id` file

**Expected output:**
```
🔧 Setting up Elastic IP for your ECS service...

📍 Allocating Elastic IP address...
✅ Elastic IP allocated: 13.211.XXX.XXX
   Allocation ID: eipalloc-1234567890abcdef0

📋 Finding your ECS task's network interface...
✅ Found network interface: eni-0987654321fedcba0

🔗 Associating Elastic IP with network interface...
✅ Elastic IP associated!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 Your static IP is ready!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Public IP: 13.211.XXX.XXX

Access your app at: http://13.211.XXX.XXX:3000/

This IP will remain the same after each deployment!

💾 IP saved to .elastic-ip file
```

### Step 3: Test Your Static IP

```bash
curl http://$(cat .elastic-ip):3000/
```

You should see your app's response.

### Step 4: Update GitHub Actions (Optional but Recommended)

To automatically re-associate the Elastic IP after each deployment, update your `.github/workflows/ci-cd.yml`:

**Add this step after the "Deploy to ECS" step:**

```yaml
  - name: Re-associate Elastic IP
    run: |
      chmod +x ./associate-elastic-ip.sh
      ./associate-elastic-ip.sh
    if: success()
```

**Full example:**

```yaml
  - name: Deploy to ECS
    run: |
      aws ecs update-service --cluster my-node-api-cluster --service node-app-service --force-new-deployment --region ap-southeast-2

  - name: Wait for deployment
    run: |
      aws ecs wait services-stable --cluster my-node-api-cluster --services node-app-service --region ap-southeast-2

  - name: Re-associate Elastic IP
    run: |
      chmod +x ./associate-elastic-ip.sh
      ./associate-elastic-ip.sh
    if: success()
```

## Manual Re-association

If you need to manually re-associate the Elastic IP after a deployment:

```bash
./associate-elastic-ip.sh
```

## Viewing Your Elastic IP in AWS Console

1. Go to **EC2** → **Elastic IPs** (under "Network & Security")
2. You'll see your allocated IP with the tag `node-app-eip`
3. It shows which network interface it's currently associated with

## Monitoring Your IP

Check your current IP at any time:

```bash
# View the saved IP
cat .elastic-ip

# Or query AWS directly
aws ec2 describe-addresses --region ap-southeast-2 --query 'Addresses[?Tags[?Key==`Name` && Value==`node-app-eip`]].PublicIp' --output text
```

## Troubleshooting

### "No running tasks found"

The script runs before your task is fully running. Wait a moment and try again:

```bash
./setup-elastic-ip.sh
```

### "You are not authorized"

Your GitHub Actions user doesn't have Elastic IP permissions yet. Follow **Step 1** above to add the IAM policy.

### "Could not find network interface ID"

Your task may not have started yet. Check ECS Console → Clusters → Tasks, then try again once the task is in "RUNNING" state.

### IP is showing as "Disassociated"

This happens during redeployment. The `associate-elastic-ip.sh` script will automatically re-associate it. Or run:

```bash
./associate-elastic-ip.sh
```

## Cost Information

- **Associated Elastic IP (while task is running)**: Free ✅
- **Disassociated Elastic IP**: $0.005/hour (~$3.60/month if left unused)
- **Release it if not using**: Use AWS Console or `aws ec2 release-address --allocation-id <ID>`

## Next Steps

1. ✅ Add IAM permissions (Step 1)
2. ✅ Run setup script (Step 2)
3. ✅ Test with curl (Step 3)
4. ✅ (Optional) Update GitHub Actions workflow (Step 4)
5. ✅ Make code changes and push - IP stays the same!

## Files Included

- `setup-elastic-ip.sh` - Initial setup (run once)
- `associate-elastic-ip.sh` - Re-associate after deployment
- `elastic-ip-policy.json` - IAM policy to attach to github-deploy-user
- `ELASTIC_IP_GUIDE.md` - This file

---

**Your app will now have a permanent home on the internet!** 🎉
