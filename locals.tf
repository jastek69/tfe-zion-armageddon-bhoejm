locals {
  ec2_key_name = "MyLinuxBox"

  common_tags = {
    Service           = "application1"
    access            = "Public"
    Owner             = "Blackneto"
    fbi               = "fit feminine and friendly"
    cia               = "men of Zion"
    zone              = "Production"
    availability_zone = "A"
  }

  instance_tags = {
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }

  user_data_template                  = "${path.module}/templates/user_data.sh.tpl"
  syslog_forwarder_user_data_template = "${path.module}/templates/syslog_forwarder_user_data.sh.tpl"

  sites = {
    tokyo = {
      display_name   = "Tokyo"
      region         = "ap-northeast-1"
      provider_alias = null
      vpc_cidr       = "10.240.0.0/16"
      vpc_name       = "TOKYO_VPC"
      instance_type  = "t3.micro"
      planet         = "Taa"
      location       = "New Genosha"
      prefix         = "tok"
      syslog_mode    = "storage"
    }
    australia = {
      display_name   = "Australia"
      region         = "ap-southeast-2"
      provider_alias = "australia"
      vpc_cidr       = "10.247.0.0/16"
      vpc_name       = "AUS_VPC"
      instance_type  = "t2.micro"
      planet         = "Genosha"
      location       = "New Wakanda"
      prefix         = "aus"
      syslog_mode    = "forwarder"
    }
    california = {
      display_name   = "California"
      region         = "us-west-1"
      provider_alias = "california"
      vpc_cidr       = "10.244.0.0/16"
      vpc_name       = "CA_VPC"
      instance_type  = "t2.micro"
      planet         = "Genosha"
      location       = "Taa"
      prefix         = "ca"
      syslog_mode    = "forwarder"
    }
    hongkong = {
      display_name   = "Hong Kong"
      region         = "ap-east-1"
      provider_alias = "hongkong"
      vpc_cidr       = "10.245.0.0/16"
      vpc_name       = "HK_VPC"
      instance_type  = "t3.micro"
      planet         = "Taa"
      location       = "Zenn La"
      prefix         = "hk"
      syslog_mode    = "forwarder"
    }
    london = {
      display_name   = "London"
      region         = "eu-west-2"
      provider_alias = "london"
      vpc_cidr       = "10.241.0.0/16"
      vpc_name       = "LONDON_VPC"
      instance_type  = "t2.micro"
      planet         = "Taa 2"
      location       = "Taa"
      prefix         = "lon"
      syslog_mode    = "forwarder"
    }
    newyork = {
      display_name   = "New York"
      region         = "us-east-1"
      provider_alias = "newyork"
      vpc_cidr       = "10.246.0.0/16"
      vpc_name       = "NY_VPC"
      instance_type  = "t2.micro"
      planet         = "Taa2"
      location       = "New Taa"
      prefix         = "ny"
      syslog_mode    = "forwarder"
    }
    saopaulo = {
      display_name   = "Sao Paulo"
      region         = "sa-east-1"
      provider_alias = "saopaulo"
      vpc_cidr       = "10.243.0.0/16"
      vpc_name       = "SAO_VPC"
      instance_type  = "t3.micro"
      planet         = "Genosha"
      location       = "New Taa"
      prefix         = "sao"
      syslog_mode    = "forwarder"
    }
  }

  tokyo_vpc_cidr = local.sites.tokyo.vpc_cidr

  foreign_vpc_cidrs = [
    for site_key, site in local.sites : site.vpc_cidr if site_key != "tokyo"
  ]
}
