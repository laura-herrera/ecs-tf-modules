/* CloudWatch Rules and Alarms */
resource "aws_cloudwatch_event_rule" "schedulable-cont" {
  name = "${var.event_rule_name}"
  description = "Monitor resources for Auto Scaling"

  schedule_expression = "${var.event_rule_schedule}"
  is_enabled = true
}

resource "aws_cloudwatch_event_target" "schedulable-cont-lambda-target" {
    target_id = "schedulable-cont-lambda-target"
    rule = "${aws_cloudwatch_event_rule.schedulable-cont.name}"
    arn = "${var.sched_cont_lambda_function}"
    input = <<EOF
{
  "cluster": "${var.cluster_name}-${var.environment}",
  "container_max_cpu": "${var.container_max_cpu}",
  "container_max_mem": "${var.container_max_mem}"
}
EOF
}

/* Add a server when the cluster is Low on Resources */
resource "aws_cloudwatch_metric_alarm" "SchedulableContainersLowAlert" {
  alarm_name = "${var.cluster_name}-${var.environment}-SchedulableLowAlert"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = "${var.low_alarm_periods}"
  metric_name = "${var.metric_name}"
  namespace = "${var.metric_namespace}"
  period = "${var.alarm_period}"
  statistic = "Average"
  threshold = "${var.low_alarm_threshold}"

  dimensions {
    ClusterName = "${var.cluster_name}-${var.environment}"
  }

  alarm_description = "This metric returns the Schedulable Containers"
  alarm_actions = ["${aws_autoscaling_policy.scale_out.arn}"]
}

/* Remove a server when there are loads of unused resources */
resource "aws_cloudwatch_metric_alarm" "SchedulableContainersHighAlert" {
  alarm_name = "${var.cluster_name}-${var.environment}-SchedulableHighAlert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = "${var.high_alarm_periods}"
  metric_name = "${var.metric_name}"
  namespace = "${var.metric_namespace}"
  period = "${var.alarm_period}"
  statistic = "Average"
  threshold = "${var.high_alarm_threshold}"

  dimensions {
    ClusterName = "${var.cluster_name}-${var.environment}"
  }

  alarm_description = "This metric returns the Schedulable Containers"
  alarm_actions = ["${aws_autoscaling_policy.scale_in.arn}"]
}

/* Add a server when there is Outdated Instances - AutoPatch */
resource "aws_cloudwatch_metric_alarm" "OutdatedInstancesAlert" {
  count = "${var.enable_autopatch ? 1 : 0}"

  alarm_name = "${var.cluster_name}-${var.environment}-OutdatedInstancesAlert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = "${var.autopatch_periods}"
  metric_name = "${var.autopatch_metric}"
  namespace = "${var.autopatch_metric_namespace}"
  period = "${var.autopatch_alarm_period}"
  statistic = "Average"
  threshold = 0

  dimensions {
    AutoScalingGroup = "${var.cluster_name}-${var.environment}-asg"
  }

  alarm_description = "This alarm returns number of Outdated Instances"
  alarm_actions = ["${aws_autoscaling_policy.outdated_instances.arn}"]
}
