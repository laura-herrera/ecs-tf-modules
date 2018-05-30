resource "aws_ecr_repository" "service_ecr" {
  count = "${var.ecr_repository_url == "" ? 1 : 0}"
  name = "${var.service_name}"
  tags {
    Name = "${var.cluster_name}-${var.environment}"
    Cluster = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
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

