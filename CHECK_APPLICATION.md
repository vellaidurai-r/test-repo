# How to Check if Your Application is Running in AWS

## Quick Check - ECS Service Status

```bash
aws ecs describe-services \
  --cluster my-node-api-cluster \
  --services node-app-service \
  --region ap-southeast-2
```

Look for:
- `"status": "ACTIVE"` - Service is active
- `"desiredCount": 1` - Desired number of tasks
- `"runningCount": 1` - Running tasks (should match desired count)

## Check Running Tasks

```bash
aws ecs list-tasks \
  --cluster my-node-api-cluster \
  --region ap-southeast-2
```

This will output task ARNs. Example:
```
arn:aws:ecs:ap-southeast-2:497162053399:task/my-node-api-cluster/abcd1234efgh5678ijkl9012mnop3456
```

## Get Task Details

```bash
# Replace <task-arn> with the ARN from previous command
aws ecs describe-tasks \
  --cluster my-node-api-cluster \
  --tasks <task-arn> \
  --region ap-southeast-2
```

Look for:
- `"lastStatus": "RUNNING"` - Task is running
- `"taskDefinitionArn"` - Which version is deployed
- `"attachments"` - Network interface details
- `"containers[0].lastStatus": "RUNNING"` - Container status

## View Application Logs

### Option 1: CloudWatch Logs

```bash
# View logs in real-time
aws logs tail /ecs/node-app-task --follow --region ap-southeast-2

# View last 20 log lines
aws logs tail /ecs/node-app-task --max-items 20 --region ap-southeast-2
```

### Option 2: Through ECS Console

1. Go to AWS Console → ECS
2. Select Cluster: `my-node-api-cluster`
3. Go to Services → `node-app-service`
4. Click on a Running task
5. Scroll down to "Logs"

## Get the Public IP Address

```bash
# Get task details
TASK_ARN=$(aws ecs list-tasks \
  --cluster my-node-api-cluster \
  --region ap-southeast-2 \
  --query 'taskArns[0]' \
  --output text)

# Get task information
aws ecs describe-tasks \
  --cluster my-node-api-cluster \
  --tasks $TASK_ARN \
  --region ap-southeast-2 \
  --query 'tasks[0].attachments[0].details' \
  --output table

# Get the ENI (Network Interface ID) from the output, then:
ENI_ID="eni-xxxxxxxxx"  # Replace with your ENI ID

aws ec2 describe-network-interfaces \
  --network-interface-ids $ENI_ID \
  --region ap-southeast-2 \
  --query 'NetworkInterfaces[0].Association.PublicIp' \
  --output text
```

## Test the Application

Once you have the public IP:

```bash
# Replace <public-ip> with the IP address from above
curl http://<public-ip>:3000

# You should see: "Hello World!"
```

Or open in browser: `http://<public-ip>:3000`

## Complete Health Check Script

```bash
#!/bin/bash

CLUSTER="my-node-api-cluster"
SERVICE="node-app-service"
REGION="ap-southeast-2"

echo "🔍 Checking ECS Service Status..."
echo ""

# Check service status
SERVICE_STATUS=$(aws ecs describe-services \
  --cluster $CLUSTER \
  --services $SERVICE \
  --region $REGION \
  --query 'services[0].[status,desiredCount,runningCount]' \
  --output text)

echo "Service Status: $SERVICE_STATUS"
echo ""

# Get running tasks
TASKS=$(aws ecs list-tasks \
  --cluster $CLUSTER \
  --region $REGION \
  --query 'taskArns[0]' \
  --output text)

if [ -z "$TASKS" ] || [ "$TASKS" == "None" ]; then
  echo "❌ No tasks running"
  exit 1
fi

echo "Running Task: $TASKS"
echo ""

# Get task details
echo "📋 Task Details:"
aws ecs describe-tasks \
  --cluster $CLUSTER \
  --tasks $TASKS \
  --region $REGION \
  --query 'tasks[0].[lastStatus,taskDefinitionArn,containers[0].lastStatus]' \
  --output table

echo ""
echo "📝 Recent Logs:"
aws logs tail /ecs/node-app-task --max-items 10 --region $REGION

echo ""
echo "🌐 Getting Public IP..."
ENI_ID=$(aws ecs describe-tasks \
  --cluster $CLUSTER \
  --tasks $TASKS \
  --region $REGION \
  --query 'tasks[0].attachments[?name==`networkInterfaceId`].value[0]' \
  --output text)

PUBLIC_IP=$(aws ec2 describe-network-interfaces \
  --network-interface-ids $ENI_ID \
  --region $REGION \
  --query 'NetworkInterfaces[0].Association.PublicIp' \
  --output text)

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" == "None" ]; then
  echo "⏳ Public IP not yet assigned (might be starting)"
else
  echo "✅ Public IP: $PUBLIC_IP"
  echo ""
  echo "🧪 Testing Application:"
  curl -s http://$PUBLIC_IP:3000
  echo ""
fi

echo ""
echo "✅ Health check complete!"
```

## Common Status Values

| Status | Meaning |
|--------|---------|
| `ACTIVE` | Service is running |
| `RUNNING` | Task/Container is running |
| `STOPPED` | Task/Container stopped |
| `STOPPING` | Task/Container is stopping |
| `PROVISIONING` | Resources being allocated |
| `PENDING` | Waiting to start |

## Troubleshooting

### Service shows ACTIVE but 0 running tasks?

```bash
# Check service events for errors
aws ecs describe-services \
  --cluster my-node-api-cluster \
  --services node-app-service \
  --region ap-southeast-2 \
  --query 'services[0].events' \
  --output table
```

### Task stuck in PROVISIONING?

- Check IAM role has correct permissions
- Check security group allows outbound to ECR
- Check subnet has internet access

### Can't reach application?

```bash
# Check security group allows port 3000
aws ec2 describe-security-groups \
  --group-ids <sg-id> \
  --region ap-southeast-2

# Check if task has public IP
aws ecs describe-tasks \
  --cluster my-node-api-cluster \
  --tasks <task-arn> \
  --region ap-southeast-2 \
  --query 'tasks[0].attachments'
```

### Check ECR Image

```bash
# Verify image is in ECR
aws ecr describe-images \
  --repository-name backend-api \
  --region ap-southeast-2
```

## One-Liner to Get Everything

```bash
CLUSTER="my-node-api-cluster"; SERVICE="node-app-service"; REGION="ap-southeast-2"; TASK=$(aws ecs list-tasks --cluster $CLUSTER --region $REGION --query 'taskArns[0]' --output text); ENI=$(aws ecs describe-tasks --cluster $CLUSTER --tasks $TASK --region $REGION --query 'tasks[0].attachments[?name==`networkInterfaceId`].value[0]' --output text); IP=$(aws ec2 describe-network-interfaces --network-interface-ids $ENI --region $REGION --query 'NetworkInterfaces[0].Association.PublicIp' --output text); echo "Application running at: http://$IP:3000"
```
