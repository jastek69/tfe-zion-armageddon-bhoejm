output "cluster_endpoint" {
  description = "Writer endpoint for the Tokyo syslog Aurora cluster."
  value       = aws_rds_cluster.syslog.endpoint
}

output "cluster_reader_endpoint" {
  description = "Reader endpoint for the Tokyo syslog Aurora cluster."
  value       = aws_rds_cluster.syslog.reader_endpoint
}

output "cluster_arn" {
  value = aws_rds_cluster.syslog.arn
}

output "security_group_id" {
  value = aws_security_group.syslog_rds.id
}

output "master_user_secret_arn" {
  description = "Secrets Manager ARN for syslog DB credentials."
  value       = aws_secretsmanager_secret.syslog_db.arn
  sensitive   = true
}

output "database_name" {
  value = aws_rds_cluster.syslog.database_name
}

output "master_username" {
  value = var.master_username
}
