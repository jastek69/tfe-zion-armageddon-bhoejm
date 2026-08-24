variable "prefix" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "planet" {
  type = string
}

variable "location" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "tgw_subnet" {
  type = object({
    cidr = string
    az   = string
  })
}

variable "public_subnets" {
  type = list(object({
    cidr          = string
    az            = string
    map_public_ip = bool
  }))
}

variable "private_subnets" {
  type = list(object({
    cidr    = string
    az      = string
    service = string
  }))
}
