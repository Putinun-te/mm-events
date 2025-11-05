resource "aws_security_group" "efs" {
  name        = "${var.name}-efs"
  description = "EFS access from Lambda or other services"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-efs"
  })
}

resource "aws_security_group_rule" "efs_ingress" {
  count = length(var.client_security_group_ids)

  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.efs.id
  source_security_group_id = var.client_security_group_ids[count.index]
}

resource "aws_efs_file_system" "this" {
  creation_token   = "${var.name}-efs"
  encrypted        = true
  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode

  lifecycle_policy {
    transition_to_ia = var.transition_to_ia
  }

  tags = merge(var.tags, {
    Name = "${var.name}-efs"
  })
}

resource "aws_efs_mount_target" "this" {
  count = length(var.subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "this" {
  file_system_id = aws_efs_file_system.this.id

  posix_user {
    gid = var.posix_gid
    uid = var.posix_uid
  }

  root_directory {
    path = var.access_point_path

    creation_info {
      owner_gid   = var.posix_gid
      owner_uid   = var.posix_uid
      permissions = "750"
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name}-efs-ap"
  })
}
