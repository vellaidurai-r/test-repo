#!/bin/bash

# build-and-push-to-ecr.sh
# Build your Node.js app and push to all environment ECR repositories

set -e

REGION="ap-southeast-2"
AWS_ACCOUNT_ID="497162053399"

echo "🔨 Building and pushing to ECR..."
echo ""

# Build Docker image
echo "📦 Building Docker image..."
docker build -t node-app:latest .

if [ $? -ne 0 ]; then
  echo "❌ Docker build failed"
  exit 1
fi

echo "✅ Build successful"
echo ""

# Function to push to ECR
push_to_ecr() {
  local ENV=$1
  local ECR_REPO="backend-api-$ENV"
  local ECR_URI="$AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO"
  
  echo "🚀 Pushing to $ENV environment (backend-api-$ENV)..."
  
  # Login to ECR
  aws ecr get-login-password --region $REGION | \
    docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
  
  # Tag image
  docker tag node-app:latest $ECR_URI:latest
  docker tag node-app:latest $ECR_URI:$(date +%s)
  
  # Push image
  docker push $ECR_URI:latest
  docker push $ECR_URI:$(date +%s)
  
  echo "✅ Pushed to $ENV"
  echo ""
}

# Push to all environments
push_to_ecr "dev"
push_to_ecr "staging"
push_to_ecr "prod"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ All images pushed to ECR!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "1. Push code to develop branch: git push origin develop"
echo "2. GitHub Actions will automatically deploy to development"
echo "3. Monitor: https://github.com/YOUR_USER/YOUR_REPO/actions"
