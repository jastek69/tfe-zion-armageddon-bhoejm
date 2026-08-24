module "site_tokyo" {
  source = "./modules/regional-site"

  providers = {
    aws = aws
  }

  prefix                            = local.sites.tokyo.prefix
  display_name                      = local.sites.tokyo.display_name
  vpc_id                            = module.network_tokyo.vpc_id
  vpc_cidr                          = local.sites.tokyo.vpc_cidr
  public_subnet_ids                 = module.network_tokyo.public_subnet_ids
  private_subnet_ids                = module.network_tokyo.private_subnet_ids
  instance_type                     = local.sites.tokyo.instance_type
  ec2_key_name                      = local.ec2_key_name
  user_data_template                = local.user_data_template
  syslog_storage_user_data_template = "${path.module}/templates/syslog_storage_user_data.sh.tpl"
  syslog_mode                       = local.sites.tokyo.syslog_mode
  tokyo_vpc_cidr                    = local.tokyo_vpc_cidr
  allowed_syslog_source_cidrs       = local.foreign_vpc_cidrs
  create_syslog_security_group      = false
  syslog_security_group_id          = aws_security_group.tokyo_syslog.id
  enable_syslog_db                  = true
  syslog_db_endpoint                = module.tokyo_syslog_db.cluster_endpoint
  syslog_db_secret_arn              = module.tokyo_syslog_db.master_user_secret_arn
  syslog_db_name                    = module.tokyo_syslog_db.database_name
  syslog_db_username                = module.tokyo_syslog_db.master_username
  common_tags                       = local.common_tags
  instance_tags                     = local.instance_tags
}

module "site_australia" {
  source = "./modules/regional-site"

  providers = {
    aws = aws.australia
  }

  prefix                              = local.sites.australia.prefix
  display_name                        = local.sites.australia.display_name
  vpc_id                              = module.network_australia.vpc_id
  vpc_cidr                            = local.sites.australia.vpc_cidr
  public_subnet_ids                   = module.network_australia.public_subnet_ids
  private_subnet_ids                  = module.network_australia.private_subnet_ids
  instance_type                       = local.sites.australia.instance_type
  ec2_key_name                        = local.ec2_key_name
  user_data_template                  = local.user_data_template
  syslog_mode                         = local.sites.australia.syslog_mode
  tokyo_vpc_cidr                      = local.tokyo_vpc_cidr
  enable_syslog_forwarder             = true
  syslog_forwarder_user_data_template = local.syslog_forwarder_user_data_template
  tokyo_syslog_endpoint               = module.site_tokyo.syslog_nlb_dns_name
  common_tags                         = local.common_tags
  instance_tags                       = local.instance_tags
}

module "site_california" {
  source = "./modules/regional-site"

  providers = {
    aws = aws.california
  }

  prefix                              = local.sites.california.prefix
  display_name                        = local.sites.california.display_name
  vpc_id                              = module.network_california.vpc_id
  vpc_cidr                            = local.sites.california.vpc_cidr
  public_subnet_ids                   = module.network_california.public_subnet_ids
  private_subnet_ids                  = module.network_california.private_subnet_ids
  instance_type                       = local.sites.california.instance_type
  ec2_key_name                        = local.ec2_key_name
  user_data_template                  = local.user_data_template
  syslog_mode                         = local.sites.california.syslog_mode
  tokyo_vpc_cidr                      = local.tokyo_vpc_cidr
  enable_syslog_forwarder             = true
  syslog_forwarder_user_data_template = local.syslog_forwarder_user_data_template
  tokyo_syslog_endpoint               = module.site_tokyo.syslog_nlb_dns_name
  common_tags                         = local.common_tags
  instance_tags                       = local.instance_tags
}

module "site_hongkong" {
  source = "./modules/regional-site"

  providers = {
    aws = aws.hongkong
  }

  prefix                              = local.sites.hongkong.prefix
  display_name                        = local.sites.hongkong.display_name
  vpc_id                              = module.network_hongkong.vpc_id
  vpc_cidr                            = local.sites.hongkong.vpc_cidr
  public_subnet_ids                   = module.network_hongkong.public_subnet_ids
  private_subnet_ids                  = module.network_hongkong.private_subnet_ids
  instance_type                       = local.sites.hongkong.instance_type
  ec2_key_name                        = local.ec2_key_name
  user_data_template                  = local.user_data_template
  syslog_mode                         = local.sites.hongkong.syslog_mode
  tokyo_vpc_cidr                      = local.tokyo_vpc_cidr
  enable_syslog_forwarder             = true
  syslog_forwarder_user_data_template = local.syslog_forwarder_user_data_template
  tokyo_syslog_endpoint               = module.site_tokyo.syslog_nlb_dns_name
  common_tags                         = local.common_tags
  instance_tags                       = local.instance_tags
}

module "site_london" {
  source = "./modules/regional-site"

  providers = {
    aws = aws.london
  }

  prefix                              = local.sites.london.prefix
  display_name                        = local.sites.london.display_name
  vpc_id                              = module.network_london.vpc_id
  vpc_cidr                            = local.sites.london.vpc_cidr
  public_subnet_ids                   = module.network_london.public_subnet_ids
  private_subnet_ids                  = module.network_london.private_subnet_ids
  instance_type                       = local.sites.london.instance_type
  ec2_key_name                        = local.ec2_key_name
  user_data_template                  = local.user_data_template
  syslog_mode                         = local.sites.london.syslog_mode
  tokyo_vpc_cidr                      = local.tokyo_vpc_cidr
  enable_syslog_forwarder             = true
  syslog_forwarder_user_data_template = local.syslog_forwarder_user_data_template
  tokyo_syslog_endpoint               = module.site_tokyo.syslog_nlb_dns_name
  common_tags                         = local.common_tags
  instance_tags                       = local.instance_tags
}

module "site_newyork" {
  source = "./modules/regional-site"

  providers = {
    aws = aws.newyork
  }

  prefix                              = local.sites.newyork.prefix
  display_name                        = local.sites.newyork.display_name
  vpc_id                              = module.network_newyork.vpc_id
  vpc_cidr                            = local.sites.newyork.vpc_cidr
  public_subnet_ids                   = module.network_newyork.public_subnet_ids
  private_subnet_ids                  = module.network_newyork.private_subnet_ids
  instance_type                       = local.sites.newyork.instance_type
  ec2_key_name                        = local.ec2_key_name
  user_data_template                  = local.user_data_template
  syslog_mode                         = local.sites.newyork.syslog_mode
  tokyo_vpc_cidr                      = local.tokyo_vpc_cidr
  enable_syslog_forwarder             = true
  syslog_forwarder_user_data_template = local.syslog_forwarder_user_data_template
  tokyo_syslog_endpoint               = module.site_tokyo.syslog_nlb_dns_name
  common_tags                         = local.common_tags
  instance_tags                       = local.instance_tags
}

module "site_saopaulo" {
  source = "./modules/regional-site"

  providers = {
    aws = aws.saopaulo
  }

  prefix                              = local.sites.saopaulo.prefix
  display_name                        = local.sites.saopaulo.display_name
  vpc_id                              = module.network_saopaulo.vpc_id
  vpc_cidr                            = local.sites.saopaulo.vpc_cidr
  public_subnet_ids                   = module.network_saopaulo.public_subnet_ids
  private_subnet_ids                  = module.network_saopaulo.private_subnet_ids
  instance_type                       = local.sites.saopaulo.instance_type
  ec2_key_name                        = local.ec2_key_name
  user_data_template                  = local.user_data_template
  syslog_mode                         = local.sites.saopaulo.syslog_mode
  tokyo_vpc_cidr                      = local.tokyo_vpc_cidr
  enable_syslog_forwarder             = true
  syslog_forwarder_user_data_template = local.syslog_forwarder_user_data_template
  tokyo_syslog_endpoint               = module.site_tokyo.syslog_nlb_dns_name
  common_tags                         = local.common_tags
  instance_tags                       = local.instance_tags
}
