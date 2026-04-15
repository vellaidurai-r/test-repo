# 🚀 Elastic IP - Quick Start

## One-Time Setup (5 minutes)

### 1. Add IAM Permission
```bash
aws iam put-user-policy --user-name github-deploy-user --policy-name ElasticIPManagement --policy-document file://elastic-ip-policy.json
```

### 2. Run Setup Script
```bash
./setup-elastic-ip.sh
```

Your output will look like:
```
🎉 Your static IP is ready!
Public IP: 13.211.XXX.XXX
Access your app at: http://13.211.XXX.XXX:3000/
```

### 3. Save This IP
```bash
cat .elastic-ip
# Output: 13.211.XXX.XXX
```

## From Now On

Every time you deploy:
- `git push` → GitHub Actions deploys
- Your app runs at the **same IP** every time ✅

## Useful Commands

```bash
# Check your static IP
cat .elastic-ip

# Test your app
curl http://$(cat .elastic-ip):3000/

# Re-associate after deployment (if needed)
./associate-elastic-ip.sh

# View in AWS Console
aws ec2 describe-addresses --region ap-southeast-2 --filters "Name=tag:Name,Values=node-app-eip"
```

## Need Help?

See full guide: `ELASTIC_IP_GUIDE.md`
