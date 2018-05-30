resource "aws_ecr_repository" "service_ecr" {
  count = "${var.ecr_repository_url == "" ? 1 : 0}"
  name = "${var.service_name}-service"
}

/* TaskDefinition */
data "template_file" "container_definition" {
  template = "${file("files/${var.template_file}")}"
  vars {
    region = "${var.region}"
    log_group = "${var.log_group}"
    task_family = "${var.task_family}"
  }
}

resource "aws_ecs_task_definition" "service_task_def" {
  family = "${var.task_family}"
  container_definitions = "${data.template_file.container_definition.rendered}"
  task_role_arn = "${aws_iam_role.task_role.arn}"

  lifecycle {
      ignore_changes = [ "container_definitions" ]
  }
}

/* Service */
resource "aws_ecs_service" "service" {
  name = "${var.service_name}"
  cluster = "${var.cluster_id}"
  task_definition = "${aws_ecs_task_definition.service_task_def.arn}"
  desired_count = "${var.desired_count}"
  iam_role = "${var.service_role}"

  load_balancer {
    target_group_arn = "${aws_alb_target_group.service_tg.arn}"
    container_name = "${var.container_name}"
    container_port = "${var.container_port}"
  }

  lifecycle {
      ignore_changes = [ "task_definition", "desired_count" ]
  }
}

/* Cloudwatch Log Group */
resource "aws_cloudwatch_log_group" "service" {
  name = "${var.log_group}"
  retention_in_days = "${var.log_retention}"
}

/* IAM Task Role */
resource "aws_iam_role" "task_role" {
  name = "${var.iam_task_role}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "task_policy" {
  name = "Parameters"
  role = "${aws_iam_role.task_role.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeParameters"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameters"
            ],
            "Resource": "arn:aws:ssm:##region##:############:parameter/${var.task_family}.*"
        }
    ]
}
EOF
}


/* Target Group for this Service */
resource "aws_alb_target_group" "service_tg" {
  name = "${var.service_name}"
  vpc_id = "${var.vpc_id}"
  port = "${var.tg_port}"
  protocol = "${var.tg_protocol}"

  health_check {
    healthy_threshold = "${var.healthcheck_healthy}"
    unhealthy_threshold = "${var.healthcheck_unhealthy}"
    path = "${var.healthcheck_path}"
    protocol = "${var.healthcheck_protocol}"
    interval = "${var.healthcheck_interval}"
    timeout = "${var.healthcheck_timeout}"
    matcher = "200"
  }
 
  stickiness {
    type = "${var.stick_type}"
    cookie_duration = "${var.stick_duration}"
    enabled = "${var.stick_enabled}"
  }
  tags {
    Name = "${var.service_name}-${var.environment}-tg"
    Cluster = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

/* Create the Listener Rule with the given URL - HTTP */
resource "aws_alb_listener_rule" "service_url_80" {
  listener_arn = "${var.alb_listener_80}"
  priority = "${var.alb_listener_rule_priority}"
  action {
    type = "forward"
    target_group_arn = "${aws_alb_target_group.service_tg.arn}"
  }
  condition {
    field = "host-header"
    values = ["${var.service_url}.${var.service_domain}"]
  }
}

/* Create the Listener Rule with the given URL - HTTPS */
resource "aws_alb_listener_rule" "service_url_443" {
  listener_arn = "${var.alb_listener_443}"
  priority = "${var.alb_listener_rule_priority}"
  action {
    type = "forward"
    target_group_arn = "${aws_alb_target_group.service_tg.arn}"
  }
  condition {
    field  = "host-header"
    values = ["${var.service_url}.${var.service_domain}"]
  }
}

/* Service Autoscaling */
resource "aws_appautoscaling_target" "service_target" {
  service_namespace  = "ecs"
  max_capacity = "${var.max_service_capacity}"
  min_capacity = "${var.min_service_capacity}"
  resource_id = "service/${var.ecs_cluster_name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
}

resource "aws_appautoscaling_policy" "scale_out" {
  count = "${var.svc_cpu_high}"

  name = "${aws_ecs_service.service.name}-scale-out"
  service_namespace = "ecs"
  resource_id = "service/${var.ecs_cluster_name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity"
    cooldown = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment = 1
    }
  }

  depends_on = ["aws_appautoscaling_target.service_target"]
}

resource "aws_appautoscaling_policy" "scale_in" {
  count = "${var.svc_cpu_low}"

  name = "${aws_ecs_service.service.name}-scale-in"
  service_namespace = "ecs"
  resource_id = "service/${var.ecs_cluster_name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity"
    cooldown = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment = -1
    }
  }

  depends_on = ["aws_appautoscaling_target.service_target"]
}

resource "aws_cloudwatch_metric_alarm" "service_cpu_high" {
  count = "${var.svc_cpu_high}"

  alarm_name = "${aws_ecs_service.service.name}-cpu-high"
  comparison_operator = "${var.svc_alarm_cpu_high_operator}"
  evaluation_periods = "${var.svc_alarm_cpu_high_periods}"
  metric_name = "CPUUtilization"
  namespace = "AWS/ECS"
  period = "${var.svc_alarm_cpu_high_period_length}"
  statistic = "Maximum"
  threshold = "${var.svc_alarm_cpu_high_threshold}"

  dimensions {
    ClusterName = "${var.ecs_cluster_name}"
    ServiceName = "${aws_ecs_service.service.name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.scale_out.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "service_cpu_low" {
  count = "${var.svc_cpu_low}"

  alarm_name = "${aws_ecs_service.service.name}-cpu-low"
  comparison_operator = "${var.svc_alarm_cpu_low_operator}"
  evaluation_periods = "${var.svc_alarm_cpu_low_periods}"
  metric_name = "CPUUtilization"
  namespace = "AWS/ECS"
  period = "${var.svc_alarm_cpu_low_period_length}"
  statistic = "Maximum"
  threshold = "${var.svc_alarm_cpu_low_threshold}"

  dimensions {
    ClusterName = "${var.ecs_cluster_name}"
    ServiceName = "${aws_ecs_service.service.name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.scale_in.arn}"]
}

/* Create DNS record as given  */
resource "aws_route53_record" "service_url" {
  zone_id = "${var.dns_zone_id}"
  name = "${var.service_url}"
  type = "A"

  alias {
    name = "${var.alb_name}"
    zone_id = "${var.alb_zone}"
    evaluate_target_health = true
  }
}
