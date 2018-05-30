output "default_vpc" {
  value = "${aws_vpc.default.id}"
}
output "default_vpc_cidr" {
  value = "${aws_vpc.default.cidr_block}"
}
output "public_subnets" {
  value = ["${aws_subnet.public.*.id}"]
}
output "private_subnets" {
  value = ["${aws_subnet.private.*.id}"]
}
output "public_sg" {
  value = "${aws_security_group.public.id}"
}
output "private_sg" {
  value = "${aws_security_group.private.id}"
}
output "private_az" {
  value = "${aws_subnet.private.*.availability_zone}"
}
output "public_rt" {
  value = "${aws_route_table.public.id}"
}
output "private_rts" {
  value = ["${aws_route_table.private.*.id}"]
}
output "public_acls" {
  value = "${aws_network_acl.public_subnet.id}"
}
output "private_acls" {
  value = "${aws_network_acl.private_subnet.id}"
}
