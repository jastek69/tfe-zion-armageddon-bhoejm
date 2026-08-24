variable "prefix" {
  type        = string
  description = "Short site prefix used in resource names (e.g. tok, aus, ny)."
}

variable "display_name" {
  type        = string
  description = "Human-readable site name shown in user-data pages."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for this regional site."
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block for this regional site."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for the port-80 application tier (minimum two AZs)."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the syslog tier (minimum two AZs)."
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for launch templates."
}

variable "ec2_key_name" {
  type        = string
  description = "EC2 key pair name."
}

variable "user_data_template" {
  type        = string
  description = "Path to the shared user-data template file."
}

variable "syslog_mode" {
  type        = string
  description = "Syslog role for this site: storage (Japan) or forwarder (foreign regions)."

  validation {
    condition     = contains(["storage", "forwarder"], var.syslog_mode)
    error_message = "syslog_mode must be either storage or forwarder."
  }
}

variable "tokyo_vpc_cidr" {
  type        = string
  description = "Tokyo VPC CIDR used for cross-region syslog routing over Transit Gateway."
}

variable "allowed_syslog_source_cidrs" {
  type        = list(string)
  description = "Source VPC CIDR blocks permitted to send syslog traffic to this site."
  default     = []
}

variable "syslog_security_group_id" {
  type        = string
  description = "Existing security group for the syslog tier when create_syslog_security_group is false."
  default     = null
}

variable "create_syslog_security_group" {
  type        = bool
  description = "When true, the module creates the syslog security group. When false, syslog_security_group_id is required."
  default     = true
}

variable "enable_syslog_db" {
  type        = bool
  description = "When true, attach IAM and storage user-data that writes syslog events to Aurora. Must be known at plan time."
  default     = false
}

variable "syslog_storage_user_data_template" {
  type        = string
  description = "User-data template used when enable_syslog_db is true."
  default     = null
}

variable "syslog_forwarder_user_data_template" {
  type        = string
  description = "User-data template used when enable_syslog_forwarder is true."
  default     = null
}

variable "enable_syslog_forwarder" {
  type        = bool
  description = "When true, use forwarder user-data that ships syslog to Tokyo over TGW. Must be known at plan time."
  default     = false
}

variable "tokyo_syslog_endpoint" {
  type        = string
  description = "Tokyo private syslog NLB DNS name for foreign forwarders (TCP 443 over TGW)."
  default     = ""
}

variable "syslog_db_endpoint" {
  type        = string
  description = "Aurora writer endpoint for Tokyo syslog storage."
  default     = ""
}

variable "syslog_db_secret_arn" {
  type        = string
  description = "Secrets Manager ARN containing DB credentials for syslog storage."
  default     = ""
}

variable "syslog_db_name" {
  type        = string
  description = "Database name for syslog storage."
  default     = ""
}

variable "syslog_db_username" {
  type        = string
  description = "Database username for syslog storage."
  default     = ""
}

variable "min_size" {
  type        = number
  description = "Minimum ASG capacity."
  default     = 1
}

variable "desired_capacity" {
  type        = number
  description = "Desired ASG capacity for the current test deployment."
  default     = 1
}

variable "max_size" {
  type        = number
  description = "Maximum ASG capacity."
  default     = 4
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to regional resources."
  default     = {}
}

variable "instance_tags" {
  type        = map(string)
  description = "Default EC2 instance tags."
  default     = {}
}
