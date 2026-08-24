output "route53_zone_id" {
  value = data.aws_route53_zone.main.zone_id
}

output "route53_query_log_group_arn" {
  value = aws_cloudwatch_log_group.route53_query_log.arn
}
