data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# Geolocation DNS: customers resolve to the nearest regional ALB.
# Country/subdivision records override continents; default catches unmatched clients.
resource "aws_route53_record" "geo" {
  for_each = var.geo_alb_targets

  zone_id        = data.aws_route53_zone.main.zone_id
  name           = var.domain_name
  type           = "A"
  set_identifier = each.key

  geolocation_routing_policy {
    country     = each.value.is_default ? "*" : try(each.value.country, null)
    continent   = each.value.is_default ? null : try(each.value.continent, null)
    subdivision = each.value.is_default ? null : try(each.value.subdivision, null)
  }

  alias {
    name                   = each.value.dns_name
    zone_id                = each.value.zone_id
    evaluate_target_health = true
  }
}

resource "aws_cloudwatch_log_group" "route53_query_log" {
  provider          = aws.us-east-1
  name              = "/aws/route53/${var.domain_name}"
  retention_in_days = 60
}

resource "aws_cloudwatch_log_resource_policy" "route53_query_logging" {
  provider    = aws.us-east-1
  policy_name = "route53-query-logging-policy"
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "route53.amazonaws.com"
        }
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "${aws_cloudwatch_log_group.route53_query_log.arn}:*"
      },
    ]
  })
}

resource "aws_route53_query_log" "public_zone" {
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53_query_log.arn
  zone_id                  = data.aws_route53_zone.main.zone_id

  depends_on = [aws_cloudwatch_log_resource_policy.route53_query_logging]
}

resource "aws_wafv2_web_acl" "tokyo" {
  name        = "tok-web-acl"
  description = "Web ACL for Tokyo"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "IPBlockRule"
    priority = 1

    action {
      block {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.tokyo_block_list.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "IPBlockRule"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputs"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "AWSManagedRulesKnownBadInputs"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "tok_WebACL"
    sampled_requests_enabled   = false
  }

  tags = {
    Name    = "tok-web-acl"
    Service = "application1"
    Owner   = "Balactus"
    Planet  = "Taa"
  }
}

resource "aws_wafv2_ip_set" "tokyo_block_list" {
  name               = "tok-ip-block-list"
  description        = "List of blocked IP addresses"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses = [
    "1.188.0.0/16",
    "1.80.0.0/16",
    "101.144.0.0/16",
    "101.16.0.0/16",
  ]

  tags = {
    Name    = "ip-block-list"
    Service = "application1"
    Owner   = "Balactus"
    Planet  = "Taa"
  }
}

resource "aws_wafv2_web_acl_association" "tokyo_alb" {
  resource_arn = var.tokyo_lb_arn
  web_acl_arn  = aws_wafv2_web_acl.tokyo.arn
}

resource "aws_iam_role" "lambda" {
  name = "tokyo_lambda_group_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = var.lambda_source_file
  output_path = var.lambda_output_path
}

resource "aws_lambda_function" "tokyo" {
  filename         = var.lambda_output_path
  function_name    = "tokyo_lambda_function_name"
  role             = aws_iam_role.lambda.arn
  handler          = "index.test"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "nodejs18.x"
}

resource "aws_iam_policy" "lambda_logging" {
  name = "tokyo-lambda-logging-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_sns_topic" "user_updates" {
  name = "user-updates-topic"
  delivery_policy = jsonencode({
    http = {
      defaultHealthyRetryPolicy = {
        minDelayTarget     = 20
        maxDelayTarget     = 20
        numRetries         = 3
        numMaxDelayRetries = 0
        numNoDelayRetries  = 0
        numMinDelayRetries = 0
        backoffFunction    = "linear"
      }
      disableSubscriptionOverrides = false
      defaultThrottlePolicy = {
        maxReceivesPerSecond = 1
      }
    }
  })
}

resource "aws_s3_bucket" "jasopstokyo" {
  bucket        = "jasopstokyo"
  force_destroy = true

  tags = {
    Name        = "jasopstokyoS3"
    Environment = "Dev"
  }
}

resource "aws_route53_resolver_query_log_config" "jasopstokyos3" {
  name            = "jasopstokyoS3"
  destination_arn = aws_s3_bucket.jasopstokyo.arn

  tags = {
    Environment = "Dev"
  }
}

resource "aws_cloudwatch_metric_alarm" "tokyo_app_cpu" {
  alarm_name          = "terraform-test-foobar5"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [var.tokyo_app_scaling_policy_arn]

  dimensions = {
    AutoScalingGroupName = var.tokyo_app_asg_name
  }
}
