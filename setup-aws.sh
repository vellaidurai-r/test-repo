#!/bin/bash

# AWS ECS Deployment Setup Script
# This script automates the creation of AWS resources for ECS deployment

set -e

# Configuration
REGION="ap-southeast-2"
AWS_ACCOUNT_ID="497162053399"
ECR_REPO="backend-api"
CLUSTER_NAME="my-node-api-cluster"
SERVICE_NAME="node-app-service"
TASK_DEFINITION="node-app-task"
CONTAINER_NAME="node-backend"

echo "🚀 Starting AWS ECS Setup..."
echo "Region: $REGION"
echo "Account ID: $AWS_ACCOUNT_ID"

# Step 1: Create ECR Repository
echo ""
echo "📦 Step 1: Creating ECR Repository..."
aws ecr create-repository \
  --repository-name $ECR_REPO \
  --region $REGION 2>/dev/null || echo "   ℹ️  Repository already exists"

# Step 2: Create IAM Role
echo ""
echo "👤 Step 2: Creating IAM Role for ECS Task Execution..."
cat > /tmp/trust-policy.json << 'EOF'
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

aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document file:///tmp/trust-policy.json \
  --region $REGION 2>/dev/null || echo "   ℹ️  Role already exists"

aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy \
  --region $REGION 2>/dev/null || echo "   ℹ️  Policy already attached"

# Step 3: Create ECS Cluster
echo ""
echo "🔗 Step 3: Creating ECS Cluster..."
aws ecs create-cluster \
  --cluster-name $CLUSTER_NAME \
  --region $REGION 2>/dev/null || echo "   ℹ️  Cluster already exists"

# Step 4: Get VPC and Subnet Information
echo ""
echo "🌐 Step 4: Retrieving VPC and Network Configuration..."
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=isDefault,Values=true" \
  --query 'Vpcs[0].VpcId' \
  --output text \
  --region $REGION)

echo "   VPC ID: $VPC_ID"

SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[0].SubnetId' \
  --output text \
  --region $REGION)

echo "   Subnet ID: $SUBNET_ID"

# Step 5: Create Security Group
echo ""
echo "🔐 Step 5: Creating Security Group..."
SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=node-app-sg" "Name=vpc-id,Values=$VPC_ID" \
  --query 'SecurityGroups[0].GroupId' \
  --output text \
  --region $REGION 2>/dev/null) || true

if [ -z "$SG_ID" ] || [ "$SG_ID" == "None" ]; then
  SG_ID=$(aws ec2 create-security-group \
    --group-name node-app-sg \
    --description "Security group for Node.js app" \
    --vpc-id $VPC_ID \
    --region $REGION \
    --query 'GroupId' \
    --output text)
  echo "   Created Security Group: $SG_ID"
  
  # Allow inbound traffic on port 3000
  aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 3000 \
    --cidr 0.0.0.0/0 \
    --region $REGION
  echo "   ✓ Allowed inbound traffic on port 3000"
else
  echo "   ℹ️  Security Group already exists: $SG_ID"
fi

# Step 6: Register Task Definition
echo ""
echo "📋 Step 6: Registering ECS Task Definition..."
cat > /tmp/ecs-task-def.json << EOF
{
  "family": "$TASK_DEFINITION",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "$CONTAINER_NAME",
      "image": "$AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000,
          "protocol": "tcp"
        }
      ],
      "memory": 512,
      "cpu": 256,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/$TASK_DEFINITION",
          "awslogs-region": "$REGION",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
EOF

aws ecs register-task-definition \
  --cli-input-json file:///tmp/ecs-task-def.json \
  --region $REGION > /dev/null
echo "   ✓ Task Definition registered"

# Step 7: Create CloudWatch Log Group
echo ""
echo "📝 Step 7: Creating CloudWatch Log Group..."
aws logs create-log-group \
  --log-group-name /ecs/$TASK_DEFINITION \
  --region $REGION 2>/dev/null || echo "   ℹ️  Log group already exists"

# Step 8: Create ECS Service
echo ""
echo "🚀 Step 8: Creating ECS Service..."
SERVICE_EXISTS=$(aws ecs describe-services \
  --cluster $CLUSTER_NAME \
  --services $SERVICE_NAME \
  --region $REGION \
  --query 'services[0].serviceName' \
  --output text 2>/dev/null) || true

if [ "$SERVICE_EXISTS" != "$SERVICE_NAME" ]; then
  aws ecs create-service \
    --cluster $CLUSTER_NAME \
    --service-name $SERVICE_NAME \
    --task-definition $TASK_DEFINITION \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],assignPublicIp=ENABLED,securityGroups=[$SG_ID]}" \
    --region $REGION > /dev/null
  echo "   ✓ Service created"
else
  echo "   ℹ️  Service already exists"
fi

# Summary
echo ""
echo "✅ AWS Setup Complete!"
echo ""
echo "📊 Configuration Summary:"
echo "   Region: $REGION"
echo "   Account ID: $AWS_ACCOUNT_ID"
echo "   ECR Repository: $ECR_REPO"
echo "   Cluster: $CLUSTER_NAME"
echo "   Service: $SERVICE_NAME"
echo "   Task Definition: $TASK_DEFINITION"
echo "   VPC ID: $VPC_ID"
echo "   Subnet ID: $SUBNET_ID"
echo "   Security Group: $SG_ID"
echo ""
echo "🔄 Next Steps:"
echo "   1. Push code to main branch"
echo "   2. GitHub Actions will build and deploy"
echo "   3. Check status: aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $REGION"
echo ""
echo "📍 View logs:"
echo "   aws logs tail /ecs/$TASK_DEFINITION --follow --region $REGION"
