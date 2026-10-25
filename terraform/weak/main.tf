module "db" {
  source = "../modules/rds-postgres"

  identifier           = "dbsec-weak"
  publicly_accessible  = true
  storage_encrypted    = false
  master_password      = var.master_password
  allowed_cidr_blocks  = ["0.0.0.0/0"]
  vpc_id               = data.aws_vpc.default.id
  subnet_ids           = data.aws_subnets.default.ids
  iam_role_policy_arn  = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "db_endpoint" {
  value = module.db.endpoint
}