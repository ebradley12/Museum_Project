
variable "DB_USERNAME" {
  description = "The username for the database"
  type        = string
  sensitive   = true  # prevents it from being displayed in logs
}

variable "DB_PASSWORD" {
  description = "The password for the database"
  type        = string
  sensitive   = true 
}

variable "DB_NAME" {
  description = "The name of the database"
  type        = string
}

variable "DB_ENGINE" {
  description = "The database engine"
  type        = string
}

variable "DB_PORT" {
  description = "The port the database listens on"
  type        = number
}

variable "AWS_REGION" {
  description = "The AWS region to deploy resources"
  type        = string
}

variable "VPC_ID" {
  description = "The VPC ID where the RDS instance will be deployed"
  type        = string
}


variable "AMI_ID" {
  description = "The AMI ID for the EC2 instance"
  type        = string
}

variable "SUBNET_ID" {
  description = "c14 subnet ID"
  type        = string
}