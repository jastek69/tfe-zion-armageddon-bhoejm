output "lb_dns_name" {
  description = "Public DNS name of the regional application load balancer."
  value       = aws_lb.app.dns_name
}

output "lb_arn" {
  description = "ARN of the regional application load balancer."
  value       = aws_lb.app.arn
}

output "lb_zone_id" {
  description = "Route53 hosted zone ID of the regional application load balancer."
  value       = aws_lb.app.zone_id
}

output "app_launch_template_id" {
  description = "Launch template ID for the application tier."
  value       = aws_launch_template.app.id
}

output "syslog_launch_template_id" {
  description = "Launch template ID for the private syslog tier."
  value       = aws_launch_template.syslog.id
}

output "app_asg_name" {
  description = "Name of the application Auto Scaling group."
  value       = aws_autoscaling_group.app.name
}

output "syslog_asg_name" {
  description = "Name of the private syslog Auto Scaling group."
  value       = aws_autoscaling_group.syslog.name
}

output "app_launch_template_arn" {
  description = "Launch template ARN for the application tier."
  value       = aws_launch_template.app.arn
}

output "syslog_launch_template_arn" {
  description = "Launch template ARN for the private syslog tier."
  value       = aws_launch_template.syslog.arn
}

output "app_scaling_policy_arn" {
  description = "ARN of the application tier target tracking scaling policy."
  value       = aws_autoscaling_policy.app_cpu.arn
}

output "syslog_mode" {
  description = "Syslog role for this site."
  value       = var.syslog_mode
}

output "syslog_security_group_id" {
  description = "Security group ID for the private syslog tier."
  value       = local.syslog_sg_id
}

output "syslog_nlb_dns_name" {
  description = "Private NLB DNS for Tokyo syslog storage (empty on forwarder sites)."
  value       = local.create_syslog_nlb ? aws_lb.syslog[0].dns_name : ""
}
