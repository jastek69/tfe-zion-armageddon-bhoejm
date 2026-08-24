# SSH key outputs

output "private_key" {
  value     = tls_private_key.MyLinuxBox.private_key_pem
  sensitive = true
}

output "public_key" {
  value = data.tls_public_key.MyLinuxBox.public_key_openssh
}

# Transit Gateway outputs

output "tokyo_tgw_id" {
  value = aws_ec2_transit_gateway.tokyo-tgw.id
}

output "london_tgw_id" {
  value = aws_ec2_transit_gateway.london-tgw.id
}

output "sao_tgw_id" {
  value = aws_ec2_transit_gateway.sao-tgw.id
}

output "ca_tgw_id" {
  value = aws_ec2_transit_gateway.ca-tgw.id
}

output "hk_tgw_id" {
  value = aws_ec2_transit_gateway.hk-tgw.id
}

output "ny_tgw_id" {
  value = aws_ec2_transit_gateway.ny-tgw.id
}

output "aus_tgw_id" {
  value = aws_ec2_transit_gateway.aus-tgw.id
}

# Regional site load balancer DNS names

output "aus-lb_dns_name" {
  description = "The DNS name of the Australia application load balancer."
  value       = module.site_australia.lb_dns_name
}

output "ca-lb_dns_name" {
  description = "The DNS name of the California application load balancer."
  value       = module.site_california.lb_dns_name
}

output "hk-lb_dns_name" {
  description = "The DNS name of the Hong Kong application load balancer."
  value       = module.site_hongkong.lb_dns_name
}

output "lon-lb_dns_name" {
  description = "The DNS name of the London application load balancer."
  value       = module.site_london.lb_dns_name
}

output "ny-lb_dns_name" {
  description = "The DNS name of the New York application load balancer."
  value       = module.site_newyork.lb_dns_name
}

output "sao-lb_dns_name" {
  description = "The DNS name of the Sao Paulo application load balancer."
  value       = module.site_saopaulo.lb_dns_name
}

output "tok-lb_dns_name" {
  description = "The DNS name of the Tokyo application load balancer."
  value       = module.site_tokyo.lb_dns_name
}

# Regional site launch template outputs (California examples retained for compatibility)

output "ca_launch_template_id_80" {
  description = "The ID of the California application launch template"
  value       = module.site_california.app_launch_template_id
}

output "ca_launch_template_arn_80" {
  description = "The ARN of the California application launch template"
  value       = module.site_california.app_launch_template_arn
}

output "ca_launch_template_id_443" {
  description = "The ID of the California private syslog launch template"
  value       = module.site_california.syslog_launch_template_id
}

output "ca_launch_template_arn_443" {
  description = "The ARN of the California private syslog launch template"
  value       = module.site_california.syslog_launch_template_arn
}

# Geo DNS / hub

output "route53_zone_id" {
  value = module.hub.route53_zone_id
}

# Tokyo syslog Aurora (Stage 2 - Japan only)

output "tokyo_syslog_db_endpoint" {
  description = "Writer endpoint for Tokyo syslog Aurora (private)."
  value       = module.tokyo_syslog_db.cluster_endpoint
}

output "tokyo_syslog_db_reader_endpoint" {
  description = "Reader endpoint for Tokyo syslog Aurora (private)."
  value       = module.tokyo_syslog_db.cluster_reader_endpoint
}

output "tokyo_syslog_db_name" {
  value = module.tokyo_syslog_db.database_name
}

output "tokyo_syslog_db_secret_arn" {
  description = "Secrets Manager ARN for the Aurora master password."
  value       = module.tokyo_syslog_db.master_user_secret_arn
  sensitive   = true
}

output "tokyo_syslog_nlb_dns_name" {
  description = "Private Tokyo syslog NLB DNS (TCP 443) reached from foreign sites over Transit Gateway."
  value       = module.site_tokyo.syslog_nlb_dns_name
}
