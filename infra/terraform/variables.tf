variable "aws_region" {
  type        = string
  default     = "eu-central-1" 
  description = "AWS region"
}

variable "instance_key_name" {
  type        = string
  description = "AWS EC2 key pair for SSH"
}

variable "environment_name" {
  type        = string
  default     = "aurora-env"
  description = "Name prefix for Aurora DevOps Platform resources"
}

variable "app_port" {
  type        = number
  default     = 8080
}

