# AWS Fargate + Elastic IP - Permission Issue Workaround

## The Problem

When using AWS Fargate, the network interfaces are created and managed by AWS, not your user account. This causes `AuthFailure` errors when trying to associate an Elastic IP to a Fargate task's ENI through a restricted IAM user account.

## Solution: Use a Broader IAM Policy

Since this is a dev/test account, we'll use a broader EC2 policy. For production, you'd want to restrict this further.

### Update Your IAM Policy

Go to AWS Console → IAM → Users → github-deploy-user → elastic-ip-policy

Replace the policy with:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EC2FullAccess",
      "Effect": "Allow",
      "Action": [
        "ec2:*"
      ],
      "Resource": "*"
    }
  ]
}
```

Or a more restricted version:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AllocateAddress",
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
        "ec2:ReleaseAddress",
        "ec2:DescribeAddresses",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeNetworkInterfaceAttribute",
        "ec2:DescribeTags",
        "ec2:CreateTags",
        "ec2:ModifyNetworkInterfaceAttribute",
        "ec2:AssignPrivateIpAddresses"
      ],
      "Resource": "*"
    }
  ]
}
```

Then wait 30 seconds and try:

```bash
./setup-elastic-ip.sh
```

---

## Manual Method (If Script Still Fails)

If the script continues to fail, use these manual commands:

```bash
# 1. Allocate Elastic IP
ALLOC=$(aws ec2 allocate-address --domain vpc --region ap-southeast-2 --query 'AllocationId' --output text)
echo "Allocation ID: $ALLOC"

# 2. Get current task's ENI
TASK_ARN=$(aws ecs list-tasks --cluster my-node-api-cluster --region ap-southeast-2 --query 'taskArns[0]' --output text)
ENI=$(aws ecs describe-tasks --cluster my-node-api-cluster --tasks $TASK_ARN --region ap-southeast-2 --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text)
echo "Network Interface: $ENI"

# 3. Associate Elastic IP
aws ec2 associate-address --allocation-id $ALLOC --network-interface-id $ENI --region ap-southeast-2

# 4. Get the public IP
PUBLIC_IP=$(aws ec2 describe-addresses --allocation-ids $ALLOC --region ap-southeast-2 --query 'Addresses[0].PublicIp' --output text)
echo "Public IP: $PUBLIC_IP"

# 5. Save for reference
echo "$PUBLIC_IP" > .elastic-ip
echo "$ALLOC" > .elastic-ip-allocation-id
```

---

## Why This Happens

- Fargate ENIs are created/managed by AWS internally
- The `github-deploy-user` account doesn't have full privileges on these AWS-managed resources
- AWS-managed resources have different permission requirements than user-created resources

## Next Steps

1. Update your IAM policy (see above)
2. Wait 30 seconds for AWS to propagate
3. Run: `./setup-elastic-ip.sh`
4. If still failing, use the manual method above

---

**Need help?** Check ELASTIC_IP_SETUP_MANUAL.md for more details.
