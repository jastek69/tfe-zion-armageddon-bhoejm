variable "vpc_id" {
  type        = string
  description = "Tokyo VPC ID."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs in at least two AZs for the DB subnet group."
}

variable "route_table_id" {
  type        = string
  description = "Route table ID for the Tokyo VPC S3 gateway endpoint."
}

variable "syslog_security_group_id" {
  type        = string
  description = "Tokyo syslog ASG security group allowed to reach the database."
}

variable "database_name" {
  type        = string
  description = "Initial database name for syslog storage."
  default     = "syslogdb"
}

variable "master_username" {
  type        = string
  description = "Master username for the Aurora cluster."
  default     = "syslogadmin"
}

variable "instance_class" {
  type        = string
  description = "Aurora instance class."
  default     = "db.t3.medium"
}

variable "instance_count" {
  type        = number
  description = "Number of Aurora instances."
  default     = 2
}

variable "common_tags" {
  type    = map(string)
  default = {}
}
