# 🖥️ ECS Exec - Terminal Access to Running Container

## What is ECS Exec?

ECS Exec lets you open an interactive shell into your running container - like SSH!

```
Your Mac → AWS → Running Container
         (interactive terminal)
```

---

## Prerequisites

✅ AWS CLI v2 (you already have this!)
✅ Session Manager plugin (need to install)
✅ Task role with proper permissions (usually pre-configured)

---

## Step 1: Install Session Manager Plugin

### On macOS:

```bash
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
unzip sessionmanager-bundle.zip
sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
rm -rf sessionmanager-bundle*
```

Or using Homebrew:

```bash
brew install --cask session-manager-plugin
```

Verify installation:

```bash
session-manager-plugin --version
```

---

## Step 2: Enable ECS Exec in Your Task

Your task should already have the required permissions, but verify:

The role `ecsTaskExecutionRole` needs policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## Step 3: Get Your Task ARN

```bash
aws ecs list-tasks --cluster my-node-api-cluster --region ap-southeast-2 --query 'taskArns[0]' --output text
```

Example output:
```
arn:aws:ecs:ap-southeast-2:497162053399:task/my-node-api-cluster/707b08e8790e4fb99b0b5eb1a2a6f619
```

---

## Step 4: Open Terminal into Container

```bash
aws ecs execute-command \
  --cluster my-node-api-cluster \
  --task <TASK_ARN> \
  --container node-backend \
  --interactive \
  --command "/bin/sh" \
  --region ap-southeast-2
```

Replace `<TASK_ARN>` with your actual task ARN.

---

## Complete Example

```bash
# Get task ARN
TASK=$(aws ecs list-tasks --cluster my-node-api-cluster --region ap-southeast-2 --query 'taskArns[0]' --output text)

# Open interactive shell
aws ecs execute-command \
  --cluster my-node-api-cluster \
  --task $TASK \
  --container node-backend \
  --interactive \
  --command "/bin/sh" \
  --region ap-southeast-2
```

---

## What You Can Do Inside Container

Once inside:

### View Files
```bash
# List files
ls -la

# View app.js
cat app.js

# Check package.json
cat package.json
```

### Check Running Processes
```bash
# List running processes
ps aux

# Find Node process
ps aux | grep node
```

### View Logs
```bash
# Check if app is listening
netstat -tlnp | grep 3000

# Or
lsof -i :3000
```

### Test Application
```bash
# From inside container, test app
curl http://localhost:3000/

# Should respond with: "Hello World is awesome! - Node.js CI/CD Pipeline on AWS ECS"
```

### Check Environment Variables
```bash
# View env vars
env

# Or specific ones
echo $PORT
echo $NODE_ENV
```

### Exit Container
```bash
exit
```

---

## Useful Commands from Container

```bash
# View current directory
pwd
# Output: /usr/src/app

# List all files
ls -la
# Output: app.js, package.json, node_modules/, etc.

# Check Node version
node --version

# Check npm version
npm --version

# View installed packages
npm list

# Check application status
curl http://localhost:3000/

# View memory usage
free -h

# Check disk space
df -h

# Check network connections
netstat -tlnp
```

---

## Helper Script

Create a script to make this easier:

```bash
#!/bin/bash

CLUSTER="my-node-api-cluster"
REGION="ap-southeast-2"
CONTAINER="node-backend"

echo "🔍 Getting current task..."
TASK=$(aws ecs list-tasks \
  --cluster $CLUSTER \
  --region $REGION \
  --query 'taskArns[0]' \
  --output text)

if [ -z "$TASK" ] || [ "$TASK" == "None" ]; then
  echo "❌ No running tasks found"
  exit 1
fi

echo "✅ Found task: $TASK"
echo ""
echo "🔌 Connecting to container..."
echo ""

aws ecs execute-command \
  --cluster $CLUSTER \
  --task $TASK \
  --container $CONTAINER \
  --interactive \
  --command "/bin/sh" \
  --region $REGION

echo ""
echo "✅ Session closed"
```

Save as `exec-container.sh`:

```bash
chmod +x exec-container.sh
./exec-container.sh
```

---

## Troubleshooting

### Error: "Exec failed: AccessDenied"

**Solution:** Check IAM role has SSM permissions

### Error: "Container not running"

**Solution:** Verify task status
```bash
aws ecs describe-tasks --cluster my-node-api-cluster --tasks <TASK_ARN> --region ap-southeast-2
```

### Error: "Session Manager plugin not found"

**Solution:** Install it
```bash
brew install --cask session-manager-plugin
```

---

## Container File Structure

Inside container:
```
/usr/src/app/
├── app.js
├── package.json
├── package-lock.json
└── node_modules/
    ├── express/
    └── ...
```

All your code is in `/usr/src/app/`

---

## Viewing Logs Inside Container

### Check if app is running
```bash
ps aux | grep node
```

### Check what port it's listening on
```bash
netstat -tlnp | grep node
# Or
lsof -i :3000
```

### Test the endpoint
```bash
curl http://localhost:3000/
```

---

## Real-World Examples

### 1. Debug: App won't start
```bash
# Inside container
cd /usr/src/app
node app.js
# See any error messages
```

### 2. Check dependencies installed
```bash
# Inside container
npm list
# Shows all installed packages
```

### 3. Inspect application code
```bash
# Inside container
cat app.js
# See your actual running code
```

### 4. Monitor running process
```bash
# Inside container
top
# See CPU/memory usage
# Press q to quit
```

### 5. Check network connectivity
```bash
# Inside container
ping google.com
# Test if container can reach internet
```

---

## Security Notes

⚠️ ECS Exec gives you **full terminal access** to the container

- Only use for debugging/troubleshooting
- Don't commit files inside container (changes are lost on redeploy)
- Container is ephemeral (temporary)
- Any changes disappear when container restarts

---

## Summary

| Task | Command |
|------|---------|
| Install Session Manager | `brew install --cask session-manager-plugin` |
| Get Task ARN | `aws ecs list-tasks --cluster my-node-api-cluster --region ap-southeast-2 --query 'taskArns[0]' --output text` |
| Access Container | `aws ecs execute-command --cluster my-node-api-cluster --task <TASK_ARN> --container node-backend --interactive --command "/bin/sh" --region ap-southeast-2` |
| View Files | `ls -la /usr/src/app/` |
| Test App | `curl http://localhost:3000/` |
| Exit | `exit` |

---

## Quick Start

```bash
# 1. Install
brew install --cask session-manager-plugin

# 2. Get task
TASK=$(aws ecs list-tasks --cluster my-node-api-cluster --region ap-southeast-2 --query 'taskArns[0]' --output text)

# 3. Connect
aws ecs execute-command --cluster my-node-api-cluster --task $TASK --container node-backend --interactive --command "/bin/sh" --region ap-southeast-2

# Inside container:
# ls -la
# cat app.js
# curl http://localhost:3000/
# exit
```

Now you can debug and inspect your running container! 🚀
