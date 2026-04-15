#!/bin/bash

# ECS Exec - Connect to running container terminal

CLUSTER="my-node-api-cluster"
REGION="ap-southeast-2"
CONTAINER="node-backend"

echo "🔍 Finding current running task..."
echo ""

# Get task ARN
TASK=$(aws ecs list-tasks \
  --cluster $CLUSTER \
  --region $REGION \
  --query 'taskArns[0]' \
  --output text)

if [ -z "$TASK" ] || [ "$TASK" == "None" ]; then
  echo "❌ Error: No running tasks found in cluster: $CLUSTER"
  echo ""
  echo "Make sure:"
  echo "  1. The service is ACTIVE"
  echo "  2. Running count is 1"
  echo "  3. You have proper AWS credentials configured"
  exit 1
fi

echo "✅ Task found: $TASK"
echo ""

# Get task details
echo "📋 Task Details:"
aws ecs describe-tasks \
  --cluster $CLUSTER \
  --tasks $TASK \
  --region $REGION \
  --query 'tasks[0].[lastStatus,containers[0].lastStatus,containers[0].name]' \
  --output table

echo ""
echo "🔌 Connecting to container: $CONTAINER"
echo ""
echo "Commands you can run inside:"
echo "  ls -la              # List files"
echo "  cat app.js          # View app code"
echo "  curl localhost:3000 # Test app"
echo "  ps aux              # Show processes"
echo "  npm list            # Show packages"
echo "  exit                # Exit terminal"
echo ""
echo "-------------------------------------------"
echo ""

# Connect to container
aws ecs execute-command \
  --cluster $CLUSTER \
  --task $TASK \
  --container $CONTAINER \
  --interactive \
  --command "/bin/sh" \
  --region $REGION

echo ""
echo "-------------------------------------------"
echo "✅ Session closed"
