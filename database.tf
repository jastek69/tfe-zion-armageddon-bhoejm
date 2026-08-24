# Stage 2: Tokyo-only Aurora for syslog storage (Japan data residency).
# Private subnets only; Tokyo syslog tier writes via Secrets Manager + VPC endpoints.

module "tokyo_syslog_db" {
  source = "./modules/tokyo-database"

  providers = {
    aws = aws
  }

  vpc_id                   = module.network_tokyo.vpc_id
  subnet_ids               = module.network_tokyo.database_subnet_ids
  route_table_id           = module.network_tokyo.route_table_id
  syslog_security_group_id = aws_security_group.tokyo_syslog.id
  database_name            = "syslogdb"
  master_username          = "syslogadmin"
  instance_class           = "db.t3.medium"
  instance_count           = 2
  common_tags              = local.common_tags
}
