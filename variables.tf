variable "kms_key_id" {
  type        = string
  description = "The ID of the AWS KMS key to use for encryption."
  sensitive   = true
}

variable "domain_name" {
  type        = string
  description = "Domain name for regional ACM certificates and Route53 records."
  default     = "jastek.click"
}
