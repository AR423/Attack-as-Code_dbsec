module "db" {
  source = "../modules/rds-postgres"

  identifier          = "dbsec-hardened"
  publicly_accessible = false
  storage_encrypted   = true
  master_password     = var.master_password

  # Restrict to the VPC's own CIDR instead of the whole internet.
  # publicly_accessible = false already blocks internet access; this is
  # defense-in-depth so the security group itself isn't also wide open.
  allowed_cidr_blocks = [data.aws_vpc.default.cidr_block]

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

  # Scoped to exactly what this role needs (RDS enhanced monitoring),
  # instead of AdministratorAccess in the weak config.
  iam_role_policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

output "db_endpoint" {
  value = module.db.endpoint
}