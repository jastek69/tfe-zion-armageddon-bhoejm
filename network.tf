module "network_tokyo" {
  source = "./modules/regional-network"

  providers = {
    aws = aws
  }

  prefix          = local.sites.tokyo.prefix
  vpc_name        = local.sites.tokyo.vpc_name
  vpc_cidr        = local.sites.tokyo.vpc_cidr
  planet          = local.sites.tokyo.planet
  location        = local.sites.tokyo.location
  common_tags     = local.common_tags
  tgw_subnet      = local.network_subnets.tokyo.tgw_subnet
  public_subnets  = local.network_subnets.tokyo.public_subnets
  private_subnets = local.network_subnets.tokyo.private_subnets
}

module "network_australia" {
  source = "./modules/regional-network"

  providers = {
    aws = aws.australia
  }

  prefix          = local.sites.australia.prefix
  vpc_name        = local.sites.australia.vpc_name
  vpc_cidr        = local.sites.australia.vpc_cidr
  planet          = local.sites.australia.planet
  location        = local.sites.australia.location
  common_tags     = local.common_tags
  tgw_subnet      = local.network_subnets.australia.tgw_subnet
  public_subnets  = local.network_subnets.australia.public_subnets
  private_subnets = local.network_subnets.australia.private_subnets
}

module "network_california" {
  source = "./modules/regional-network"

  providers = {
    aws = aws.california
  }

  prefix          = local.sites.california.prefix
  vpc_name        = local.sites.california.vpc_name
  vpc_cidr        = local.sites.california.vpc_cidr
  planet          = local.sites.california.planet
  location        = local.sites.california.location
  common_tags     = local.common_tags
  tgw_subnet      = local.network_subnets.california.tgw_subnet
  public_subnets  = local.network_subnets.california.public_subnets
  private_subnets = local.network_subnets.california.private_subnets
}

module "network_hongkong" {
  source = "./modules/regional-network"

  providers = {
    aws = aws.hongkong
  }

  prefix          = local.sites.hongkong.prefix
  vpc_name        = local.sites.hongkong.vpc_name
  vpc_cidr        = local.sites.hongkong.vpc_cidr
  planet          = local.sites.hongkong.planet
  location        = local.sites.hongkong.location
  common_tags     = local.common_tags
  tgw_subnet      = local.network_subnets.hongkong.tgw_subnet
  public_subnets  = local.network_subnets.hongkong.public_subnets
  private_subnets = local.network_subnets.hongkong.private_subnets
}

module "network_london" {
  source = "./modules/regional-network"

  providers = {
    aws = aws.london
  }

  prefix          = local.sites.london.prefix
  vpc_name        = local.sites.london.vpc_name
  vpc_cidr        = local.sites.london.vpc_cidr
  planet          = local.sites.london.planet
  location        = local.sites.london.location
  common_tags     = local.common_tags
  tgw_subnet      = local.network_subnets.london.tgw_subnet
  public_subnets  = local.network_subnets.london.public_subnets
  private_subnets = local.network_subnets.london.private_subnets
}

module "network_newyork" {
  source = "./modules/regional-network"

  providers = {
    aws = aws.newyork
  }

  prefix          = local.sites.newyork.prefix
  vpc_name        = local.sites.newyork.vpc_name
  vpc_cidr        = local.sites.newyork.vpc_cidr
  planet          = local.sites.newyork.planet
  location        = local.sites.newyork.location
  common_tags     = local.common_tags
  tgw_subnet      = local.network_subnets.newyork.tgw_subnet
  public_subnets  = local.network_subnets.newyork.public_subnets
  private_subnets = local.network_subnets.newyork.private_subnets
}

module "network_saopaulo" {
  source = "./modules/regional-network"

  providers = {
    aws = aws.saopaulo
  }

  prefix          = local.sites.saopaulo.prefix
  vpc_name        = local.sites.saopaulo.vpc_name
  vpc_cidr        = local.sites.saopaulo.vpc_cidr
  planet          = local.sites.saopaulo.planet
  location        = local.sites.saopaulo.location
  common_tags     = local.common_tags
  tgw_subnet      = local.network_subnets.saopaulo.tgw_subnet
  public_subnets  = local.network_subnets.saopaulo.public_subnets
  private_subnets = local.network_subnets.saopaulo.private_subnets
}
