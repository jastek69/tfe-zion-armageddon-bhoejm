# Tokyo is the default region.
provider "aws" {
  region = local.sites.tokyo.region
}

provider "aws" {
  alias  = "australia"
  region = local.sites.australia.region
}

provider "aws" {
  alias  = "california"
  region = local.sites.california.region
}

provider "aws" {
  alias  = "hongkong"
  region = local.sites.hongkong.region
}

provider "aws" {
  alias  = "london"
  region = local.sites.london.region
}

provider "aws" {
  alias  = "newyork"
  region = local.sites.newyork.region
}

provider "aws" {
  alias  = "saopaulo"
  region = local.sites.saopaulo.region
}

# CloudWatch and WAF resources that must live in us-east-1.
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.46.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "s3" {
    bucket = "taaops-terraform-state-tokyo"
    key    = "MyLinuxBox"
    region = "ap-northeast-1"
  }
}
