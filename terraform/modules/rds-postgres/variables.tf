variable "identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "publicly_accessible" {
  description = "Whether the DB is publicly accessible"
  type        = bool
}

variable "storage_encrypted" {
  description = "Whether storage is encrypted"
  type        = bool
}

variable "master_password" {
  description = "Master DB password"
  type        = string
  sensitive   = true
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach the DB security group"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC to deploy into"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for the DB subnet group"
  type        = list(string)
}

variable "iam_role_policy_arn" {
  description = "Policy ARN to attach to the DB's associated IAM role (used to seed the over-permissive IAM misconfiguration)"
  type        = string
}