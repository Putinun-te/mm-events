resource "random_password" "master" {
  length           = 20
  special          = true
  override_special = "!@#-_"
}

resource "aws_security_group" "db" {
  name        = "${var.name}-db"
  description = "Allow database access from application security groups"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-db"
  })
}

resource "aws_security_group_rule" "db_ingress" {
  count = length(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = var.allowed_security_group_ids[count.index]
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name}-db-subnets"
  })
}

resource "aws_db_instance" "this" {
  identifier                 = "${var.name}-db"
  engine                     = var.engine
  engine_version             = var.engine_version
  instance_class             = var.instance_class
  allocated_storage          = var.allocated_storage
  max_allocated_storage      = var.max_allocated_storage
  storage_type               = var.storage_type
  db_subnet_group_name       = aws_db_subnet_group.this.name
  vpc_security_group_ids     = [aws_security_group.db.id]
  username                   = var.username
  password                   = random_password.master.result
  db_name                    = var.database_name
  port                       = var.port
  multi_az                   = var.multi_az
  storage_encrypted          = true
  deletion_protection        = var.deletion_protection
  publicly_accessible        = false
  skip_final_snapshot        = var.skip_final_snapshot
  backup_retention_period    = var.backup_retention_days
  auto_minor_version_upgrade = true
  performance_insights_enabled = var.performance_insights_enabled
  monitoring_interval          = var.monitoring_interval

  tags = merge(var.tags, {
    Name = "${var.name}-db"
  })
}

resource "aws_secretsmanager_secret" "credentials" {
  name = "${var.name}/database"

  tags = merge(var.tags, {
    Name = "${var.name}-db-secret"
  })
}

resource "aws_secretsmanager_secret_version" "credentials" {
  secret_id     = aws_secretsmanager_secret.credentials.id
  secret_string = jsonencode({
    username = var.username,
    password = random_password.master.result,
    engine   = var.engine,
    host     = aws_db_instance.this.address,
    port     = var.port,
    dbname   = var.database_name
  })
}
