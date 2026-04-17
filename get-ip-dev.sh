#!/bin/bash

CLUSTER="my-node-api-cluster-dev"
SERVICE="node-app-service-dev"
REGION="ap-southeast-2"

echo "🔍 Finding current public IP for $SERVICE..."
echo ""

TASK_ARN=$(aws ecs list-tasks --cluster $CLUSTER --region $REGION --query 'taskArns[0]' --output text)

if [ -z "$TASK_ARN" ] || [ "$TASK_ARN" == "None" ]; then
  echo "❌ No running tasks found in $CLUSTER"
  exit 1
fi

echo "Task ARN: $TASK_ARN"
echo ""

ENI=$(aws ecs describe-tasks --cluster $CLUSTER --tasks $TASK_ARN --region $REGION --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text)

if [ -z "$ENI" ] || [ "$ENI" == "None" ]; then
  echo "❌ No network interface found"
  exit 1
fi

echo "Network Interface: $ENI"
echo ""

PUBLIC_IP=$(aws ec2 describe-network-interfaces --network-interface-ids $ENI --region $REGION --query 'NetworkInterfaces[0].Association.PublicIp' --output text)

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" == "None" ]; then
  echo "⏳ Public IP not yet assigned. Waiting..."
  sleep 10
  PUBLIC_IP=$(aws ec2 describe-network-interfaces --network-interface-ids $ENI --region $REGION --query 'NetworkInterfaces[0].Association.PublicIp' --output text)
fi

echo "✅ Current Public IP: $PUBLIC_IP"
echo ""
echo "📍 Access your app at:"
echo "   http://$PUBLIC_IP:3000/"
echo ""

read -p "Test connection? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  curl http://$PUBLIC_IP:3000/
fi
