variable "cluster_name" {}
variable "environment" {}
variable "region" {}
variable "ecs_instance_type" {}
variable "docker_registry" {}
variable "ECR_RO_policy" {}
variable "SSM_policy" {}
variable "CW_LOGS_policy" {}
variable "CW_CM_policy" {}
variable "ECS_policy" {}
variable "key_name" {}
variable "ecs_amis" { type = "map" }
variable "public_zone" {}
variable "private_zone" {}
variable "availability_zones" { type = "map" }
variable "default_vpc" {}
variable "default_vpc_cidr" {}
variable "public_subnets" { type = "list" }
variable "private_subnets" { type = "list" }
variable "public_sg" {}
variable "private_sg" {}
variable "private_az" { type = "list" }
variable "ssl_cert_external_domain" {}
variable "ssl_external_security_policy" {}
variable "ssl_cert_internal_domain" {}
variable "ssl_internal_security_policy" {}
variable "alb_internal" {}
variable "alb_external" {}
variable "protocol_btg" {}
variable "port_btg" {}
variable "healthy_threshold_btg_hc" {}
variable "unhealthy_threshold_btg_hc" {}
variable "path_btg_hc" {}
variable "protocol_btg_hc" {}
variable "interval_btg_hc" {}
variable "timeout_btg_hc" {}
variable "min_size" {}
variable "max_size" {}
variable "desired_capacity" {}
variable "default_cooldown" {}
variable "health_check_grace_period" {}
variable "enabled_metrics" { type = "list" }
variable "sched_cont_lambda_function" {}
variable "event_rule_name" {}
variable "event_rule_schedule" {}
variable "metric_name" {}
variable "metric_namespace" {}
variable "container_max_cpu" {}
variable "container_max_mem" {}
variable "alarm_period" {}
variable "low_alarm_periods" {}
variable "low_alarm_threshold" {}
variable "high_alarm_periods" {}
variable "high_alarm_threshold" {}
variable "notification_topic" {
  default = "##ARN for the Auto Scaling Group Topic for ECS ##"
}
variable "SNS_role" {
  default = "## ARN for the IAM role for Lambda to communicate with SNS ##"
}
variable "enable_autopatch" {}
variable "autopatch_metric" {}
variable "autopatch_metric_namespace" {}
variable "autopatch_periods" {}
variable "autopatch_alarm_period" {}
