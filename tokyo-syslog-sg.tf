# Shared Tokyo syslog SG (breaks circular dep between site_tokyo and tokyo_syslog_db).

resource "aws_security_group" "tokyo_syslog" {
  name_prefix = "tok-syslog-"
  description = "Tokyo private syslog storage tier"
  vpc_id      = module.network_tokyo.vpc_id

  ingress {
    description = "Syslog from Tokyo VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.sites.tokyo.vpc_cidr]
  }

  ingress {
    description = "Syslog TCP from foreign VPCs via Transit Gateway"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.foreign_vpc_cidrs
  }

  ingress {
    description = "Syslog UDP from foreign VPCs via Transit Gateway"
    from_port   = 514
    to_port     = 514
    protocol    = "udp"
    cidr_blocks = local.foreign_vpc_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name    = "tok-syslog-sg"
    Service = "syslog"
  })

  lifecycle {
    create_before_destroy = true
  }
}
