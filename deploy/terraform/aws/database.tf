# RDS MySQL 8 in the private subnets. RDS generates the master password and keeps it in
# Secrets Manager (manage_master_user_password), so it never appears in Terraform state.

resource "aws_db_subnet_group" "main" {
  name       = var.project
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_parameter_group" "mysql" {
  name   = "${var.project}-mysql8"
  family = "mysql8.0"

  # Reject unencrypted connections
  parameter {
    name  = "require_secure_transport"
    value = "1"
  }
}

resource "aws_db_instance" "mysql" {
  identifier     = var.project
  engine         = "mysql"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name                     = var.db_name
  username                    = var.db_username
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  parameter_group_name   = aws_db_parameter_group.mysql.name
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period    = 7
  auto_minor_version_upgrade = true
  deletion_protection        = var.deletion_protection
  skip_final_snapshot        = !var.deletion_protection
  final_snapshot_identifier  = var.deletion_protection ? "${var.project}-final" : null
}
