resource "aws_security_group" "cache" {
  name        = "${var.name}-cache"
  description = "Redis access control"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-cache"
  })
}

resource "aws_security_group_rule" "cache_ingress" {
  count = length(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cache.id
  source_security_group_id = var.allowed_security_group_ids[count.index]
}

resource "aws_elasticache_serverless_cache" "this" {
  name                        = "${var.name}-redis"
  engine                      = "redis"
  cache_usage_limits {
    data_storage {
      maximum = var.max_data_storage_gb
      unit    = "GB"
    }
    ecpu_per_second {
      maximum = var.max_ecpu_per_second
    }
  }
  security_group_ids          = concat([aws_security_group.cache.id], var.additional_security_group_ids)
  subnet_ids                  = var.subnet_ids
  daily_snapshot_time         = var.daily_snapshot_time
  kms_key_id                  = var.kms_key_id != "" ? var.kms_key_id : null
  description                 = var.description

  tags = merge(var.tags, {
    Name = "${var.name}-redis"
  })
}
