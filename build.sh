#!/usr/bin/env bash 
# DON'T run this randomly , i created it when i was building this project 
# these are separate commands to run during stages to build different stages 

# create two ECR repos on AWS (one for backend, and another for frontend)
# reference: https://docs.aws.amazon.com/AmazonECR/latest/userguide/getting-started-cli.html
aws ecr create-repository --repsoitory-name backend-app --region us-east-1 
aws ecr create-repository --repsoitory-name frontend-app --region us-east-1 

# to delete ecr repo : 
aws ecr delete-repository --repository-name --force backend-app --region us-east-1
aws ecr delete-repository --repository-name --force frontend-app --region us-east-1


#=====================================================================
# configure the s3 backend for terrafrom 
# create the s3 bucket 
aws s3api create-bucket \
  --bucket three-tier-terraform-eks-gitops-bucket \
  --region us-east-1

# enbale versioning 
aws s3api put-bucket-versioning \
  --bucket three-tier-terraform-eks-gitops-bucket \
  --versioning-configuration Status=Enabled

# create a dynamoDB table with a table named "lockID", terraform requires this exact name
# dynamodb locking became legacy now, use s3-native locking these days.
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1


## for me 

private_subnet_ids = [
  "subnet-0893a1fb5eb8d13c2",
  "subnet-082ea9bba24e66b2b",
]
public_subnet_ids = [
  "subnet-022a1996339ca3db1",
  "subnet-0710689555f475ac0",
]
vpc_id = "vpc-0d5652fcb82a0ff6b"

## import the two ECR repositories 
terraform import \
  'module.ecr.aws_ecr_repository.backend' \
  backend-app

terraform import \
  'module.ecr.aws_ecr_repository.frontend' \
  frontend-app


# connect kubectl to the eks cluster 
aws eks update-kubeconfig --region us-east-1 --name dev-eks

# ECR
# get images tags for repos
aws ecr describe-repositories   # list repos 
aws ecr describe-images --repsoitory-name frontend-app 


# create helm chart
cd helm 
helm create my-app 