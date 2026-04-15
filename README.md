# Hello World Node.js App - CI/CD Pipeline

This project demonstrates a complete CI/CD pipeline for a Node.js application deployed on AWS ECS.

## Architecture

- **Application**: Simple Express.js "Hello World" server
- **Container Registry**: AWS ECR (Elastic Container Registry)
- **Orchestration**: AWS ECS (Elastic Container Service) Fargate
- **CI/CD**: GitHub Actions

## Prerequisites

- AWS Account with credentials configured
- GitHub repository with secrets:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
- AWS Resources:
  - ECS Cluster: `my-node-api-cluster`
  - ECR Repository: `backend-api`
  - ECS Service: `node-app-service`

## AWS Configuration Details

| Resource | Value |
|----------|-------|
| Region | ap-southeast-2 |
| AWS Account ID | 497162053399 |
| ECR Repo | backend-api |
| ECR URI | 497162053399.dkr.ecr.ap-southeast-2.amazonaws.com/backend-api |
| ECS Cluster | my-node-api-cluster |
| ECS Service | node-app-service |
| Task Definition | node-app-task |
| Container Name | node-backend |

## Local Development

```bash
# Install dependencies
npm install

# Run the application
npm start

# Application will be available at http://localhost:3000
```

## CI/CD Pipeline

When you push to the `main` branch:

1. **Build**: Docker image is built from the `Dockerfile`
2. **Push**: Image is tagged and pushed to AWS ECR
3. **Deploy**: ECS task definition is updated with the new image
4. **Update Service**: ECS service is updated to use the new task definition

## Dockerfile

The Dockerfile uses `node:18-alpine` for a minimal image size with production dependencies only.

## Troubleshooting

### ECR Login Issues
Ensure AWS credentials have ECR permissions:
```bash
aws ecr get-authorization-token --region ap-southeast-2
```

### ECS Deployment Issues
Check the ECS task logs in AWS Console under the Cluster → Service → Tasks section.

### GitHub Actions Workflow Issues
Review the workflow logs in GitHub repository → Actions tab.

## File Structure

```
.
├── app.js                  # Main Express application
├── package.json           # Node.js dependencies
├── Dockerfile             # Container definition
├── ecs-task-def.json      # ECS task definition
├── .github/
│   └── workflows/
│       └── ci-cd.yml      # GitHub Actions workflow
├── .gitignore             # Git ignore rules
└── README.md              # This file
```
