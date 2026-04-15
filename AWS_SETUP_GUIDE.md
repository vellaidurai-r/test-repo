# AWS ECS Setup Guide

This guide walks you through setting up the required AWS resources for your Node.js application deployment.

## Prerequisites

- AWS CLI installed and configured
- AWS Account with appropriate permissions
- Region: `ap-southeast-2`

## Step 1: Create ECR Repository

```bash
aws ecr create-repository \
  --repository-name backend-api \
  --region ap-southeast-2
```

**Expected Output:**
```json
{
  "repository": {
    "repositoryArn": "arn:aws:ecr:ap-southeast-2:497162053399:repository/backend-api",
    "registryId": "497162053399",
    "repositoryName": "backend-api",
    "repositoryUri": "497162053399.dkr.ecr.ap-southeast-2.amazonaws.com/backend-api",
    "createdAt": "2026-04-15T00:00:00+00:00",
    "imageTagMutability": "MUTABLE",
    "imageScanningConfiguration": {
      "scanOnPush": false
    }
  }
}
```

## Step 2: Create IAM Role for ECS Task Execution

```bash
# Create the trust policy
cat > trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the role
aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document file://trust-policy.json \
  --region ap-southeast-2

# Attach the policy for ECR access
aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy \
  --region ap-southeast-2
```

## Step 3: Create ECS Cluster

```bash
aws ecs create-cluster \
  --cluster-name my-node-api-cluster \
  --region ap-southeast-2
```

## Step 4: Register ECS Task Definition

```bash
aws ecs register-task-definition \
  --cli-input-json file://ecs-task-def.json \
  --region ap-southeast-2
```

**Note:** Make sure the `ecs-task-def.json` in your repository has the correct image URI.

## Step 5: Create ECS Service

```bash
# First, get your VPC and subnet information
aws ec2 describe-vpcs --region ap-southeast-2

# Then create the service
aws ecs create-service \
  --cluster my-node-api-cluster \
  --service-name node-app-service \
  --task-definition node-app-task \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxxxxxxxx],assignPublicIp=ENABLED,securityGroups=[sg-xxxxxxxxx]}" \
  --region ap-southeast-2
```

**Replace:**
- `subnet-xxxxxxxxx` - Your VPC subnet ID
- `sg-xxxxxxxxx` - Your security group ID

## Step 6: Create Security Group (if needed)

```bash
# Get your VPC ID
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text --region ap-southeast-2)

# Create security group
aws ec2 create-security-group \
  --group-name node-app-sg \
  --description "Security group for Node.js app" \
  --vpc-id $VPC_ID \
  --region ap-southeast-2

# Get the security group ID
SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=node-app-sg" --query 'SecurityGroups[0].GroupId' --output text --region ap-southeast-2)

# Allow inbound traffic on port 3000
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 3000 \
  --cidr 0.0.0.0/0 \
  --region ap-southeast-2

# Allow outbound traffic (typically all)
aws ec2 authorize-security-group-egress \
  --group-id $SG_ID \
  --protocol -1 \
  --cidr 0.0.0.0/0 \
  --region ap-southeast-2
```

## Step 7: Verify Deployment

```bash
# Check service status
aws ecs describe-services \
  --cluster my-node-api-cluster \
  --services node-app-service \
  --region ap-southeast-2

# Check running tasks
aws ecs list-tasks \
  --cluster my-node-api-cluster \
  --region ap-southeast-2

# Get task details
aws ecs describe-tasks \
  --cluster my-node-api-cluster \
  --tasks <task-arn> \
  --region ap-southeast-2
```

## Step 8: Access Your Application

Once the service is running, get the public IP:

```bash
# Get the ENI (Network Interface) from the task
aws ecs describe-tasks \
  --cluster my-node-api-cluster \
  --tasks <task-arn> \
  --region ap-southeast-2 \
  --query 'tasks[0].attachments[0].details'

# Get the public IP from the ENI
aws ec2 describe-network-interfaces \
  --network-interface-ids <eni-id> \
  --region ap-southeast-2 \
  --query 'NetworkInterfaces[0].Association.PublicIp'
```

Then access: `http://<public-ip>:3000`

## Continuous Deployment

After AWS resources are set up:

1. **Push to main branch** → GitHub Actions triggers
2. **Build Docker image** → Pushed to ECR
3. **Update task definition** → New image is registered
4. **Deploy to ECS** → Service automatically updates

Your application is now deployed! 🚀

## Troubleshooting

### Check CloudWatch Logs

```bash
aws logs describe-log-groups --region ap-southeast-2
aws logs tail /ecs/node-app-task --follow --region ap-southeast-2
```

### View ECS Events

```bash
aws ecs describe-services \
  --cluster my-node-api-cluster \
  --services node-app-service \
  --region ap-southeast-2 \
  --query 'services[0].events'
```

### Check IAM Permissions

Ensure the IAM user/role used in GitHub Actions has:
- `ecr:GetAuthorizationToken`
- `ecr:BatchCheckLayerAvailability`
- `ecr:GetDownloadUrlForLayer`
- `ecr:PutImage`
- `ecr:InitiateLayerUpload`
- `ecr:UploadLayerPart`
- `ecr:CompleteLayerUpload`
- `ecs:DescribeTaskDefinition`
- `ecs:DescribeServices`
- `ecs:DescribeTaskDefinition`
- `ecs:UpdateService`
- `iam:PassRole`
