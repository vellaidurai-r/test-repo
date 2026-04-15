#!/bin/bash

# setup-multi-env.sh
# This script creates AWS resources for Development, Staging, and Production environments

set -e

REGION="ap-southeast-2"
AWS_ACCOUNT_ID="497162053399"

echo "🚀 Setting up multi-environment AWS infrastructure..."
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

create_environment() {
  local ENV=$1
  
  echo -e "${BLUE}Creating $ENV environment...${NC}"
  echo ""
  
  # Create ECS Cluster
  echo "📦 Creating ECS Cluster: my-node-api-cluster-$ENV"
  aws ecs create-cluster \
    --cluster-name my-node-api-cluster-$ENV \
    --region $REGION \
    --tags key=Environment,value=$ENV key=ManagedBy,value=terraform 2>/dev/null || echo "   (Cluster may already exist)"
  
  # Create ECR Repository
  echo "📦 Creating ECR Repository: backend-api-$ENV"
  aws ecr create-repository \
    --repository-name backend-api-$ENV \
    --region $REGION \
    --tags key=Environment,value=$ENV 2>/dev/null || echo "   (Repository may already exist)"
  
  # Create CloudWatch Log Group
  echo "📦 Creating CloudWatch Log Group: /ecs/node-app-task-$ENV"
  aws logs create-log-group \
    --log-group-name /ecs/node-app-task-$ENV \
    --region $REGION 2>/dev/null || echo "   (Log group may already exist)"
  
  # Set log retention to 7 days
  aws logs put-retention-policy \
    --log-group-name /ecs/node-app-task-$ENV \
    --retention-in-days 7 \
    --region $REGION 2>/dev/null || true
  
  echo -e "${GREEN}✅ $ENV environment resources created!${NC}"
  echo ""
}

# Create resources for each environment
create_environment "dev"
create_environment "staging"
create_environment "prod"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ Multi-environment infrastructure setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 Next steps:"
echo "1. Update your VPC configuration in MULTI_ENV_SETUP.md"
echo "2. Create ECS Services for each environment"
echo "3. Create Git branches: develop and staging"
echo "4. Push to test the CI/CD workflow"
echo ""
echo "Need help? See MULTI_ENV_SETUP.md for detailed instructions."
