output "vpc_id" {
  description = "ID of the created VPC — the EKS module will need this"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets — used for the ALB"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets — EKS worker nodes will launch here"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateway(s), exposed mainly for debugging/visibility"
  value       = aws_nat_gateway.main[*].id
}