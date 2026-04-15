# 🔧 Update IAM Policy - IMPORTANT

Your Elastic IP script needs one more permission: **ec2:CreateTags**

## Quick Fix (AWS Console)

1. Go to: **https://console.aws.amazon.com/iam/home#/users**
2. Click **github-deploy-user**
3. Scroll to **Permissions policies**
4. Find **elastic-ip-policy** policy
5. Click it to expand, then click **Edit**
6. Click **JSON** tab
7. Replace with this updated version:

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
        "ec2:ReleaseAddress",
        "ec2:CreateTags",
        "ec2:ModifyNetworkInterfaceAttribute"
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

8. Click **Save changes**
9. Wait 30 seconds for AWS to update
10. Try again:

```bash
./setup-elastic-ip.sh
```

---

## What Changed?

Added `"ec2:CreateTags"` to allow tagging the Elastic IP with:
- `Name=node-app-eip`
- `Service=node-app-service`

This helps you identify the IP in AWS Console easily.

---

## Did you update the policy?

Once updated, run:
```bash
./setup-elastic-ip.sh
```

It should work now! 🚀
