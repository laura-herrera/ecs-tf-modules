output "ecr_dummy_repo_url" {
  value = "############.dkr.ecr.eu-west-1.amazonaws.com/dummy"
}
output "iam_svc_role" {
  value = "${aws_iam_role.svc_role.id}"
}
output "alb_svc_tg" {
  value = "${aws_alb_target_group.default_svc.arn}"
}
output "ecs_cluster" {
 value = "${aws_ecs_cluster.default.id}"
}
output "ecs_cluster_name" {
 value = "${aws_ecs_cluster.default.name}"
}
output "external_alb" {
  value = "${aws_alb.external_alb.id}"
}
output "external_alb_name" {
  value = "${aws_alb.external_alb.dns_name}"
}
output "external_alb_zone" {
  value = "${aws_alb.external_alb.zone_id}"
}
output "external_alb_sg" {
  value = "${aws_security_group.external_alb.id}"
}
output "internal_alb" {
  value = "${aws_alb.internal_alb.arn}"
}
output "internal_alb_name" {
  value = "${aws_alb.internal_alb.dns_name}"
}
output "internal_alb_zone" {
  value = "${aws_alb.internal_alb.zone_id}"
}
output "internal_alb_sg" {
  value = "${aws_security_group.internal_alb.id}"
}
output "frontend_80_listener" {
  value = "${element(concat(aws_alb_listener.frontend_80.*.arn, list("")), 0)}"
}
output "frontend_443_listener" {
  value = "${element(concat(aws_alb_listener.frontend_443.*.arn, list("")), 0)}"
}
output "internal_80_listener" {
  value = "${element(concat(aws_alb_listener.internal_80.*.arn, list("")), 0)}"
}
output "internal_443_listener" {
  value = "${element(concat(aws_alb_listener.internal_443.*.arn, list("")), 0)}"
}
