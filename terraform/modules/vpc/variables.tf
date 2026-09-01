
variable "project_name" {
  description = "Used as a prefix on resource Name tag"
  type        = string
}

variable "environment" {
  description = "dev / prod — used in tags and to keep resource names unique per environment"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the whole VPC"
  type        = string
}

variable "azs" {
  description = "Availability Zones to spread subnets across"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "One CIDR per AZ "
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "One CIDR per AZ for private subnets"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "one NAT Gateway shared by all private subnets"
  type        = bool
  default     = true
}