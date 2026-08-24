resource "random_password" "master" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_kms_key" "syslog_rds" {
  description             = "KMS key for Tokyo syslog Aurora encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(var.common_tags, {
    Name    = "tok-syslog-rds-kms"
    Service = "syslog"
  })
}

resource "aws_kms_alias" "syslog_rds" {
  name          = "alias/tok-syslog-rds"
  target_key_id = aws_kms_key.syslog_rds.key_id
}

resource "aws_security_group" "syslog_rds" {
  name_prefix = "tok-rds-"
  description = "Tokyo syslog Aurora - private MySQL from syslog tier only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL/Aurora from Tokyo syslog collectors only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.syslog_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name    = "tok-syslog-rds-sg"
    Service = "syslog"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "tok-vpce-"
  description = "VPC interface endpoints for Secrets Manager and KMS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTPS from Tokyo syslog tier"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.syslog_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "tok-syslog-vpce-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "syslog" {
  name        = "tok-syslog-private-subnet-group"
  description = "Private subnets for Tokyo syslog Aurora (Japan only)"
  subnet_ids  = var.subnet_ids

  tags = merge(var.common_tags, {
    Name    = "tok-syslog-db-subnet-group"
    Service = "syslog"
  })
}

resource "aws_rds_cluster" "syslog" {
  cluster_identifier = "tok-syslog-aurora"
  engine             = "aurora-mysql"
  engine_mode        = "provisioned"
  database_name      = var.database_name
  master_username    = var.master_username
  master_password    = random_password.master.result

  db_subnet_group_name   = aws_db_subnet_group.syslog.name
  vpc_security_group_ids = [aws_security_group.syslog_rds.id]

  storage_encrypted = true
  kms_key_id        = aws_kms_key.syslog_rds.arn

  backup_retention_period = 7
  preferred_backup_window = "14:00-15:00"
  skip_final_snapshot     = true
  deletion_protection     = false
  copy_tags_to_snapshot   = true

  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  tags = merge(var.common_tags, {
    Name    = "tok-syslog-aurora"
    Service = "syslog"
    Planet  = "Japan"
  })
}

resource "aws_rds_cluster_instance" "syslog" {
  count = var.instance_count

  identifier           = "tok-syslog-aurora-${count.index}"
  cluster_identifier   = aws_rds_cluster.syslog.id
  instance_class       = var.instance_class
  engine               = aws_rds_cluster.syslog.engine
  engine_version       = aws_rds_cluster.syslog.engine_version
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.syslog.name

  tags = merge(var.common_tags, {
    Name    = "tok-syslog-aurora-${count.index}"
    Service = "syslog"
  })
}

resource "aws_secretsmanager_secret" "syslog_db" {
  name       = "tok-syslog-aurora-credentials"
  kms_key_id = aws_kms_key.syslog_rds.arn

  tags = merge(var.common_tags, {
    Name    = "tok-syslog-aurora-credentials"
    Service = "syslog"
  })
}

resource "aws_secretsmanager_secret_version" "syslog_db" {
  secret_id = aws_secretsmanager_secret.syslog_db.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master.result
    host     = aws_rds_cluster.syslog.endpoint
    port     = 3306
    dbname   = var.database_name
    engine   = "mysql"
  })
}

data "aws_region" "current" {}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [var.route_table_id]

  tags = merge(var.common_tags, {
    Name = "tok-syslog-s3-endpoint"
  })
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.common_tags, {
    Name = "tok-syslog-secretsmanager-endpoint"
  })
}

resource "aws_vpc_endpoint" "kms" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.kms"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.common_tags, {
    Name = "tok-syslog-kms-endpoint"
  })
}

# Session Manager requires these interface endpoints in private subnets (no NAT).
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.common_tags, {
    Name = "tok-syslog-ssm-endpoint"
  })
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.common_tags, {
    Name = "tok-syslog-ssmmessages-endpoint"
  })
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.common_tags, {
    Name = "tok-syslog-ec2messages-endpoint"
  })
}
