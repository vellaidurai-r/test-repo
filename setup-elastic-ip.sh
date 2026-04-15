#!/bin/bash

# setup-elastic-ip.sh
# This script allocates an Elastic IP and associates it with your ECS Fargate task
# Run this ONCE to set up your static IP

set -e

REGION="ap-southeast-2"
CLUSTER_NAME="my-node-api-cluster"
SERVICE_NAME="node-app-service"

echo "🔧 Setting up Elastic IP for your ECS service..."
echo ""

# Step 1: Allocate Elastic IP
echo "📍 Allocating Elastic IP address..."
ALLOCATION_RESPONSE=$(aws ec2 allocate-address \
  --domain vpc \
  --region $REGION \
  --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=node-app-eip},{Key=Service,Value=node-app-service}]')

ALLOCATION_ID=$(echo $ALLOCATION_RESPONSE | jq -r '.AllocationId')
PUBLIC_IP=$(echo $ALLOCATION_RESPONSE | jq -r '.PublicIp')

echo "✅ Elastic IP allocated: $PUBLIC_IP"
echo "   Allocation ID: $ALLOCATION_ID"
echo ""

# Step 2: Get current task's network interface
echo "📋 Finding your ECS task's network interface..."
TASK_ARN=$(aws ecs list-tasks \
  --cluster $CLUSTER_NAME \
  --region $REGION \
  --query 'taskArns[0]' \
  --output text)

if [ -z "$TASK_ARN" ] || [ "$TASK_ARN" == "None" ]; then
  echo "❌ Error: No running tasks found in cluster $CLUSTER_NAME"
  echo ""
  echo "⚠️  Your Elastic IP has been allocated but not associated."
  echo "   Allocation ID: $ALLOCATION_ID"
  echo "   Public IP: $PUBLIC_IP"
  echo ""
  echo "   Please run './associate-elastic-ip.sh' once your task is running."
  exit 1
fi

TASK_DETAILS=$(aws ecs describe-tasks \
  --cluster $CLUSTER_NAME \
  --tasks $TASK_ARN \
  --region $REGION)

ENI_ID=$(echo $TASK_DETAILS | jq -r '.tasks[0].attachments[] | select(.type=="ElasticNetworkInterface") | .details[] | select(.name=="networkInterfaceId") | .value')

if [ -z "$ENI_ID" ]; then
  echo "❌ Error: Could not find network interface ID"
  exit 1
fi

echo "✅ Found network interface: $ENI_ID"
echo ""

# Step 3: Associate Elastic IP with network interface
echo "🔗 Associating Elastic IP with network interface..."
aws ec2 associate-address \
  --allocation-id $ALLOCATION_ID \
  --network-interface-id $ENI_ID \
  --region $REGION

echo "✅ Elastic IP associated!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Your static IP is ready!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Public IP: $PUBLIC_IP"
echo ""
echo "Access your app at: http://$PUBLIC_IP:3000/"
echo ""
echo "This IP will remain the same after each deployment!"
echo ""

# Save the IP to a file for reference
echo "$PUBLIC_IP" > .elastic-ip

echo "💾 IP saved to .elastic-ip file"
