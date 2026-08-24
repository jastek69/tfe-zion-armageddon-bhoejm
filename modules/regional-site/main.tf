data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "alb" {
  name_prefix = "${var.prefix}-alb-"
  description = "Public ALB - port 80 only"
  vpc_id      = var.vpc_id

  ingress {
    description = "Public HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.prefix}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "app" {
  name_prefix = "${var.prefix}-app-"
  description = "Application tier - HTTP from ALB only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.prefix}-app-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  syslog_sg_id = var.create_syslog_security_group ? aws_security_group.syslog[0].id : var.syslog_security_group_id

  syslog_db_enabled        = var.enable_syslog_db && var.syslog_storage_user_data_template != null
  syslog_forwarder_enabled = var.enable_syslog_forwarder && var.syslog_forwarder_user_data_template != null
  create_syslog_nlb        = var.syslog_mode == "storage"

  syslog_user_data = (
    local.syslog_db_enabled ? base64encode(templatefile(var.syslog_storage_user_data_template, {
      headline_line1 = "Keisha threat detected ... Syslog Storage Deployed"
      headline_line2 = "${var.display_name} writing syslog to Japan Aurora"
      db_endpoint    = var.syslog_db_endpoint
      db_secret_arn  = var.syslog_db_secret_arn
      db_name        = var.syslog_db_name
      db_username    = var.syslog_db_username
    })) :
    local.syslog_forwarder_enabled ? base64encode(templatefile(var.syslog_forwarder_user_data_template, {
      headline_line1        = "Keisha threat detected ... Syslog Forwarder Deployed"
      headline_line2        = "${var.display_name} forwarding syslog to Japan over TGW"
      display_name          = var.display_name
      tokyo_syslog_endpoint = var.tokyo_syslog_endpoint
    })) :
    base64encode(templatefile(var.user_data_template, {
      headline_line1 = var.syslog_mode == "storage" ? "Keisha threat detected ... Syslog Storage Deployed" : "Keisha threat detected ... Syslog Forwarder Deployed"
      headline_line2 = "${var.display_name} private security zone is active"
    }))
  )
}

resource "aws_security_group" "syslog" {
  count = var.create_syslog_security_group ? 1 : 0

  name_prefix = "${var.prefix}-syslog-"
  description = "Private syslog tier - no public ingress"
  vpc_id      = var.vpc_id

  ingress {
    description = "Syslog from local VPC application tier"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  dynamic "ingress" {
    for_each = var.allowed_syslog_source_cidrs
    content {
      description = "Syslog forwarded from remote site via Transit Gateway"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.prefix}-syslog-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "syslog_assume" {
  count = local.syslog_db_enabled ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "syslog" {
  count = local.syslog_db_enabled ? 1 : 0

  name               = "${var.prefix}-syslog-role"
  assume_role_policy = data.aws_iam_policy_document.syslog_assume[0].json

  tags = merge(var.common_tags, {
    Name = "${var.prefix}-syslog-role"
  })
}

data "aws_iam_policy_document" "syslog_db_access" {
  count = local.syslog_db_enabled ? 1 : 0

  statement {
    sid     = "ReadSyslogDbSecret"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      var.syslog_db_secret_arn,
    ]
  }

  statement {
    sid = "DecryptSyslogSecret"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "syslog_db_access" {
  count = local.syslog_db_enabled ? 1 : 0

  name   = "${var.prefix}-syslog-db-access"
  role   = aws_iam_role.syslog[0].id
  policy = data.aws_iam_policy_document.syslog_db_access[0].json
}

resource "aws_iam_role_policy_attachment" "syslog_ssm" {
  count = local.syslog_db_enabled ? 1 : 0

  role       = aws_iam_role.syslog[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "syslog" {
  count = local.syslog_db_enabled ? 1 : 0

  name = "${var.prefix}-syslog-profile"
  role = aws_iam_role.syslog[0].name
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.prefix}-app-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.ec2_key_name

  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = base64encode(templatefile(var.user_data_template, {
    headline_line1 = "Balactus has Arrived in ${var.display_name}"
    headline_line2 = "Keisha World has been consumed"
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.instance_tags, {
      Name = "${var.prefix}-app"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_template" "syslog" {
  name_prefix   = "${var.prefix}-syslog-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.ec2_key_name

  dynamic "iam_instance_profile" {
    for_each = local.syslog_db_enabled ? [1] : []
    content {
      name = aws_iam_instance_profile.syslog[0].name
    }
  }

  vpc_security_group_ids = [local.syslog_sg_id]

  user_data = local.syslog_user_data

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.instance_tags, {
      Name    = "${var.prefix}-syslog"
      Service = "syslog"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "app" {
  name        = "${var.prefix}-app-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200"
  }

  tags = merge(var.common_tags, {
    Name = "${var.prefix}-app-tg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "app" {
  name                       = "${var.prefix}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = var.public_subnet_ids
  enable_deletion_protection = false

  tags = merge(var.common_tags, {
    Name    = "${var.prefix}-load-balancer"
    Service = "LoadBalancer"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_autoscaling_group" "app" {
  name_prefix               = "${var.prefix}-app-asg-"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.public_subnet_ids
  health_check_type         = "ELB"
  health_check_grace_period = 300
  force_delete              = true
  target_group_arns         = [aws_lb_target_group.app.arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances",
  ]

  tag {
    key                 = "Name"
    value               = "${var.prefix}-app-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "application"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "app_cpu" {
  name                   = "${var.prefix}-app-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 75.0
  }
}

resource "aws_lb_target_group" "syslog" {
  count = local.create_syslog_nlb ? 1 : 0

  name        = "${var.prefix}-syslog-tg"
  port        = 443
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = "443"
    interval            = 30
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = merge(var.common_tags, {
    Name = "${var.prefix}-syslog-tg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "syslog" {
  count = local.create_syslog_nlb ? 1 : 0

  name                             = "${var.prefix}-syslog-nlb"
  internal                         = true
  load_balancer_type               = "network"
  subnets                          = var.private_subnet_ids
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  tags = merge(var.common_tags, {
    Name    = "${var.prefix}-syslog-nlb"
    Service = "syslog"
  })
}

resource "aws_lb_listener" "syslog" {
  count = local.create_syslog_nlb ? 1 : 0

  load_balancer_arn = aws_lb.syslog[0].arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.syslog[0].arn
  }
}

resource "aws_autoscaling_group" "syslog" {
  name_prefix               = "${var.prefix}-syslog-asg-"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.private_subnet_ids
  health_check_type         = "EC2"
  health_check_grace_period = 300
  force_delete              = true
  target_group_arns         = local.create_syslog_nlb ? [aws_lb_target_group.syslog[0].arn] : []

  launch_template {
    id      = aws_launch_template.syslog.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances",
  ]

  tag {
    key                 = "Name"
    value               = "${var.prefix}-syslog-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = var.syslog_mode == "storage" ? "syslog-storage" : "syslog-forwarder"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "syslog_cpu" {
  name                   = "${var.prefix}-syslog-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.syslog.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 75.0
  }
}
