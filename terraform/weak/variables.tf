variable "master_password" {
  description = "Master DB password (set in terraform.tfvars, which is gitignored)"
  type        = string
  sensitive   = true
}