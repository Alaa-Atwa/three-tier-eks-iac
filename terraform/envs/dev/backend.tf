# comment this section until you run terraform apply for the first time and 
# created the s3 bucket resource and dynamodb table with a fixed table name "LockID"

terraform {
  backend "s3" {
    bucket         = "three-tier-terraform-eks-gitops-bucket"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks" # this is what makes DynamoDB provide LOCKING: prevents two people/CI runs whne someone working on the file. 
    encrypt        = true
  }
}

# after configuring run the terraform init again 