#!/bin/bash

# Get current public IP of running ECS task

CLUSTER="my-node-api-cluster"
SERVICE="node-app-service"
REGION="ap-southeast-2"

echo "🔍 Finding current public IP for $SERVICE..."
echo ""

# Get task ARN
TASK_ARN=$(aws ecs list-tasks \
  --cluster $CLUSTER \
  --region $REGION \
  --query 'taskArns[0]' \
  --output text)

if [ -z "$TASK_ARN" ] || [ "$TASK_ARN" == "None" ]; then
  echo "❌ No running tasks found"
  exit 1
fi

echo "Task ARN: $TASK_ARN"
echo ""

# Get network interface ID
ENI=$(aws ecs describe-tasks \
  --cluster $CLUSTER \
  --tasks $TASK_ARN \
  --region $REGION \
  --query 'tasks[0].attachments[0].details' \
  --output text | grep networkInterfaceId | awk '{print $2}')

if [ -z "$ENI" ] || [ "$ENI" == "None" ]; then
  echo "❌ Could not find network interface"
  exit 1
fi

echo "Network Interface: $ENI"
echo ""

# Get public IP
PUBLIC_IP=$(aws ec2 describe-network-interfaces \
  --network-interface-ids $ENI \
  --region $REGION \
  --query 'NetworkInterfaces[0].Association.PublicIp' \
  --output text)

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" == "None" ]; then
  echo "❌ No public IP assigned"
  exit 1
fi

echo "✅ Current Public IP: $PUBLIC_IP"
echo ""
echo "📍 Access your app at:"
echo "   http://$PUBLIC_IP:3000/"
echo ""

# Optional: Try to access it
read -p "Test connection? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Testing..."
  curl -s http://$PUBLIC_IP:3000/ | head -c 50
  echo ""
fi
