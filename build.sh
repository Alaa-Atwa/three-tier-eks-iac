# create two ECR repos on AWS (one for backend, and another for frontend)
# reference: https://docs.aws.amazon.com/AmazonECR/latest/userguide/getting-started-cli.html
aws ecr create-repository --repsoitory-name backend-app --region us-east-1 
aws ecr create-repository --repsoitory-name frontend-app --region us-east-1 

# to delete ecr repo : 
aws ecr delete-repository --repository-name --force backend-app --region us-east-1
aws ecr delete-repository --repository-name --force frontend-app --region us-east-1


