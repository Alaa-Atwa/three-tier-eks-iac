variable "backend_repository_name" {
  description = "ECR repository name for the backend"
  type        = string
  default     = "backend-app"
}

variable "frontend_repository_name" {
  description = "ECR repository name for the frontend"
  type        = string
  default     = "frontend-app"
}