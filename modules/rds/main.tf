# RDS module: single Postgres instance (v1 scope - Multi-AZ intentionally
# deferred, see envs README). Master password is managed by AWS
# (manage_master_user_password = true) and stored in Secrets Manager
# automatically, so no DB password ever appears in Terraform config,
# state diffs, or tfvars.

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.name}-db-subnet-group"
  }
}

resource "aws_security_group" "db" {
  name        = "${var.name}-db"
  description = "RDS Postgres security group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-db-sg"
  }
}

resource "aws_security_group_rule" "db_ingress" {
  for_each = toset(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = each.value
}

resource "aws_db_instance" "this" {
  identifier     = "${var.name}-db"
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.master_username

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]

  multi_az = var.multi_az

  backup_retention_period = var.backup_retention_period
  backup_window           = "07:00-09:00"
  maintenance_window      = "sun:09:30-sun:10:30"

  # v1: allow Terraform to manage deletion directly, but always take a
  # final snapshot rather than silently discarding patient-adjacent data.
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.name}-db-final-snapshot"
  deletion_protection       = var.deletion_protection

  tags = {
    Name = "${var.name}-db"
  }
}
