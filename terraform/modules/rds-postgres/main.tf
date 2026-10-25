resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Project = "attack-as-code"
  }
}

resource "aws_security_group" "db" {
  name        = "${var.identifier}-sg"
  description = "Security group for ${var.identifier} RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    description = "Postgres access"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "attack-as-code"
  }
}

# IAM role attached to the DB instance's monitoring/enhanced-monitoring role.
# Used to seed the "over-permissive IAM role" misconfiguration in the weak config
# (by passing a broad policy ARN like AdministratorAccess) vs. a scoped one in hardened.
resource "aws_iam_role" "rds_role" {
  name = "${var.identifier}-rds-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }]
  })

  tags = {
    Project = "attack-as-code"
  }
}

resource "aws_iam_role_policy_attachment" "rds_role_policy" {
  role       = aws_iam_role.rds_role.name
  policy_arn = var.iam_role_policy_arn
}

resource "aws_db_instance" "this" {
  identifier             = var.identifier
  engine                 = "postgres"
  engine_version         = "16.4"
  instance_class         = "db.t4g.micro"
  allocated_storage      = 20
  db_name                = "dbsecproject"
  username               = "dbadmin"
  password               = var.master_password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = var.publicly_accessible
  storage_encrypted      = var.storage_encrypted
  skip_final_snapshot    = true
  monitoring_role_arn    = aws_iam_role.rds_role.arn

  tags = {
    Project = "attack-as-code"
  }
}

output "endpoint" {
  value = aws_db_instance.this.endpoint
}

output "security_group_id" {
  value = aws_security_group.db.id
}