locals {
  network_subnets = {
    tokyo = {
      tgw_subnet = { cidr = "10.240.0.0/24", az = "ap-northeast-1a" }
      public_subnets = [
        { cidr = "10.240.1.0/24", az = "ap-northeast-1a", map_public_ip = false },
        { cidr = "10.240.3.0/24", az = "ap-northeast-1c", map_public_ip = true },
      ]
      private_subnets = [
        { cidr = "10.240.11.0/24", az = "ap-northeast-1a", service = "application1" },
        { cidr = "10.240.43.0/24", az = "ap-northeast-1c", service = "syslog" },
        { cidr = "10.240.54.0/24", az = "ap-northeast-1d", service = "database" },
      ]
    }
    australia = {
      tgw_subnet = { cidr = "10.247.0.0/24", az = "ap-southeast-2a" }
      public_subnets = [
        { cidr = "10.247.1.0/24", az = "ap-southeast-2a", map_public_ip = true },
        { cidr = "10.247.2.0/24", az = "ap-southeast-2b", map_public_ip = false },
      ]
      private_subnets = [
        { cidr = "10.247.11.0/24", az = "ap-southeast-2a", service = "application1" },
        { cidr = "10.247.12.0/24", az = "ap-southeast-2b", service = "application1" },
      ]
    }
    california = {
      tgw_subnet = { cidr = "10.244.0.0/24", az = "us-west-1a" }
      public_subnets = [
        { cidr = "10.244.1.0/24", az = "us-west-1a", map_public_ip = false },
        { cidr = "10.244.2.0/24", az = "us-west-1b", map_public_ip = false },
      ]
      private_subnets = [
        { cidr = "10.244.11.0/24", az = "us-west-1a", service = "application1" },
        { cidr = "10.244.12.0/24", az = "us-west-1b", service = "application1" },
      ]
    }
    hongkong = {
      tgw_subnet = { cidr = "10.245.0.0/24", az = "ap-east-1a" }
      public_subnets = [
        { cidr = "10.245.1.0/24", az = "ap-east-1a", map_public_ip = false },
        { cidr = "10.245.2.0/24", az = "ap-east-1b", map_public_ip = false },
      ]
      private_subnets = [
        { cidr = "10.245.11.0/24", az = "ap-east-1a", service = "application1" },
        { cidr = "10.245.12.0/24", az = "ap-east-1b", service = "application1" },
      ]
    }
    london = {
      tgw_subnet = { cidr = "10.241.0.0/24", az = "eu-west-2a" }
      public_subnets = [
        { cidr = "10.241.1.0/24", az = "eu-west-2a", map_public_ip = true },
        { cidr = "10.241.2.0/24", az = "eu-west-2b", map_public_ip = false },
      ]
      private_subnets = [
        { cidr = "10.241.11.0/24", az = "eu-west-2a", service = "application1" },
        { cidr = "10.241.12.0/24", az = "eu-west-2b", service = "application1" },
      ]
    }
    newyork = {
      tgw_subnet = { cidr = "10.246.0.0/24", az = "us-east-1a" }
      public_subnets = [
        { cidr = "10.246.1.0/24", az = "us-east-1a", map_public_ip = true },
        { cidr = "10.246.2.0/24", az = "us-east-1b", map_public_ip = false },
      ]
      private_subnets = [
        { cidr = "10.246.11.0/24", az = "us-east-1a", service = "application1" },
        { cidr = "10.246.12.0/24", az = "us-east-1b", service = "application1" },
      ]
    }
    saopaulo = {
      tgw_subnet = { cidr = "10.243.0.0/24", az = "sa-east-1a" }
      public_subnets = [
        { cidr = "10.243.1.0/24", az = "sa-east-1a", map_public_ip = false },
        { cidr = "10.243.2.0/24", az = "sa-east-1b", map_public_ip = true },
      ]
      private_subnets = [
        { cidr = "10.243.11.0/24", az = "sa-east-1a", service = "application1" },
        { cidr = "10.243.12.0/24", az = "sa-east-1b", service = "application1" },
      ]
    }
  }
}
