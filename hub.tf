module "hub" {
  source = "./modules/hub"

  providers = {
    aws           = aws
    aws.us-east-1 = aws.us-east-1
  }

  domain_name = var.domain_name

  # Geolocation DNS: country/subdivision first, then continents, then default → Tokyo.
  geo_alb_targets = {
    default = {
      dns_name   = module.site_tokyo.lb_dns_name
      zone_id    = module.site_tokyo.lb_zone_id
      is_default = true
    }
    japan = {
      dns_name = module.site_tokyo.lb_dns_name
      zone_id  = module.site_tokyo.lb_zone_id
      country  = "JP"
    }
    hong_kong = {
      dns_name = module.site_hongkong.lb_dns_name
      zone_id  = module.site_hongkong.lb_zone_id
      country  = "HK"
    }
    australia = {
      dns_name = module.site_australia.lb_dns_name
      zone_id  = module.site_australia.lb_zone_id
      country  = "AU"
    }
    united_kingdom = {
      dns_name = module.site_london.lb_dns_name
      zone_id  = module.site_london.lb_zone_id
      country  = "GB"
    }
    brazil = {
      dns_name = module.site_saopaulo.lb_dns_name
      zone_id  = module.site_saopaulo.lb_zone_id
      country  = "BR"
    }
    us_new_york = {
      dns_name    = module.site_newyork.lb_dns_name
      zone_id     = module.site_newyork.lb_zone_id
      country     = "US"
      subdivision = "NY"
    }
    us_california = {
      dns_name    = module.site_california.lb_dns_name
      zone_id     = module.site_california.lb_zone_id
      country     = "US"
      subdivision = "CA"
    }
    continent_asia = {
      dns_name  = module.site_tokyo.lb_dns_name
      zone_id   = module.site_tokyo.lb_zone_id
      continent = "AS"
    }
    continent_europe = {
      dns_name  = module.site_london.lb_dns_name
      zone_id   = module.site_london.lb_zone_id
      continent = "EU"
    }
    continent_oceania = {
      dns_name  = module.site_australia.lb_dns_name
      zone_id   = module.site_australia.lb_zone_id
      continent = "OC"
    }
    continent_south_america = {
      dns_name  = module.site_saopaulo.lb_dns_name
      zone_id   = module.site_saopaulo.lb_zone_id
      continent = "SA"
    }
    continent_north_america = {
      dns_name  = module.site_newyork.lb_dns_name
      zone_id   = module.site_newyork.lb_zone_id
      continent = "NA"
    }
  }

  tokyo_lb_arn                 = module.site_tokyo.lb_arn
  tokyo_app_asg_name           = module.site_tokyo.app_asg_name
  tokyo_app_scaling_policy_arn = module.site_tokyo.app_scaling_policy_arn
  lambda_source_file           = "${path.module}/lambda.js"
  lambda_output_path           = "${path.module}/tokyo_lambda_function_payload.zip"
}
