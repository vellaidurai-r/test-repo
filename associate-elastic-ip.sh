#!/bin/bash

# associate-elastic-ip.sh
# This script associates your Elastic IP with the current task after deployment
# This is run automatically by GitHub Actions after each deployment

set -e

REGION="ap-southeast-2"
CLUSTER_NAME="my-node-api-cluster"
ALLOCATION_ID_FILE=".elastic-ip-allocation-id"

# Check if allocation ID file exists
if [ ! -f "$ALLOCATION_ID_FILE" ]; then
  echo "❌ Error: Elastic IP allocation ID not found in $ALLOCATION_ID_FILE"
  echo "   Run './setup-elastic-ip.sh' first to set up your Elastic IP"
  exit 1
fi

ALLOCATION_ID=$(cat "$ALLOCATION_ID_FILE")

echo "🔄 Re-associating Elastic IP after deployment..."
echo "   Allocation ID: $ALLOCATION_ID"
echo ""

# Get current task's network interface
echo "📋 Finding current task's network interface..."
TASK_ARN=$(aws ecs list-tasks \
  --cluster $CLUSTER_NAME \
  --region $REGION \
  --query 'taskArns[0]' \
  --output text)

if [ -z "$TASK_ARN" ] || [ "$TASK_ARN" == "None" ]; then
  echo "❌ Error: No running tasks found"
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

# Disassociate from old interface if needed (in case of previous association)
echo "🔍 Checking for previous associations..."
OLD_ASSOCIATION=$(aws ec2 describe-addresses \
  --allocation-ids $ALLOCATION_ID \
  --region $REGION \
  --query 'Addresses[0].AssociationId' \
  --output text 2>/dev/null)

if [ ! -z "$OLD_ASSOCIATION" ] && [ "$OLD_ASSOCIATION" != "None" ]; then
  echo "   Found previous association: $OLD_ASSOCIATION"
  echo "   Disassociating..."
  aws ec2 disassociate-address \
    --association-id $OLD_ASSOCIATION \
    --region $REGION
  
  # Wait for disassociation
  sleep 2
fi

echo ""
echo "🔗 Associating Elastic IP with new network interface..."
aws ec2 associate-address \
  --allocation-id $ALLOCATION_ID \
  --network-interface-id $ENI_ID \
  --region $REGION

echo "✅ Elastic IP re-associated!"
echo ""

# Get and display the IP
PUBLIC_IP=$(aws ec2 describe-addresses \
  --allocation-ids $ALLOCATION_ID \
  --region $REGION \
  --query 'Addresses[0].PublicIp' \
  --output text)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ Your app is now at: http://$PUBLIC_IP:3000/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
