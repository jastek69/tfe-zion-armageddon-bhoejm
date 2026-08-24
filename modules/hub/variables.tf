variable "domain_name" {
  type = string
}

variable "geo_alb_targets" {
  type = map(object({
    dns_name    = string
    zone_id     = string
    country     = optional(string)
    continent   = optional(string)
    subdivision = optional(string)
    is_default  = optional(bool, false)
  }))
  description = "Geolocation Route53 alias targets keyed by set identifier."
}

variable "tokyo_lb_arn" {
  type = string
}

variable "tokyo_app_asg_name" {
  type = string
}

variable "tokyo_app_scaling_policy_arn" {
  type = string
}

variable "lambda_source_file" {
  type    = string
  default = "lambda.js"
}

variable "lambda_output_path" {
  type    = string
  default = "tokyo_lambda_function_payload.zip"
}
