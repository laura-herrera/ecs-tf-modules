output "service_id" {
  value = "${aws_ecs_service.service.id}"
}
output "service_name" {
  value = "${aws_ecs_service.service.name}"
}
output "service_cluster" {
  value = "${aws_ecs_service.service.cluster}"
}
output "svc_target_group_id" {
  value = "${aws_alb_target_group.service_tg.id}"
}
output "svc_target_group_arn" {
  value = "${aws_alb_target_group.service_tg.arn}"
}
output "svc_scale_out_policy_name" {
  value = "${element(concat(aws_appautoscaling_policy.scale_out.*.name, list("")), 0)}"
}
output "svc_scale_out_policy_arn" {
  value = "${element(concat(aws_appautoscaling_policy.scale_out.*.arn, list("")), 0)}"
}
output "svc_scale_in_policy_name" {
  value = "${element(concat(aws_appautoscaling_policy.scale_in.*.name, list("")), 0)}"
}
output "svc_scale_in_policy_arn" {
  value = "${element(concat(aws_appautoscaling_policy.scale_in.*.arn, list("")), 0)}"
}
