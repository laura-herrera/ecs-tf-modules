/* Create a Peering Connection with extrnal VPC */
resource "aws_vpc_peering_connection" "external_vpc_peering" {
  peer_vpc_id = "${var.local_vpc}"
  vpc_id = "${var.external_vpc}"
  auto_accept = true

  tags {
    Name = "${var.external_name}-${var.cluster_name}-${var.environment}-Peering"
    Cluster = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

/* Add the new route to existing external Route Table */
resource "aws_route" "external_rt" {
  count = "${length(var.external_rts)}"

  route_table_id = "${element(var.external_rts, count.index)}"
  destination_cidr_block = "${var.local_cidr}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.external_vpc_peering.id}"
}

/* Add a route to the corresponding local private RTs */
resource "aws_route" "route_to_local_rt" {
  count = "${var.az_count}"

  route_table_id = "${element(var.local_private_rts, count.index)}"
  destination_cidr_block = "${var.external_cidr}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.external_vpc_peering.id}"
}

/* Add a route to the public RT, when needed */
resource "aws_route" "pub_in" {
    count = "${var.add_public_route}"

    route_table_id = "${var.local_public_rt}"
    destination_cidr_block = "${var.external_cidr}"
    vpc_peering_connection_id = "${aws_vpc_peering_connection.external_vpc_peering.id}"
}

/* Add a rule to the relevant Security Group */
resource "aws_security_group_rule" "allow_external" {
  type = "ingress"
  from_port = "${var.sg_port_from}"
  to_port = "${var.sg_port_to}"
  protocol = "tcp"
  cidr_blocks = ["${var.external_cidr}"]
  security_group_id = "${var.local_sg}"
}

/* Add the Private Network ACLs for the new routes */
resource "aws_network_acl_rule" "in_private" {
    count = "${var.add_in_pri_acl}"

    network_acl_id = "${var.local_network_private_acls}"
    egress = false
    protocol = "tcp"
    rule_number = "${var.acl_rule_number}"
    rule_action = "allow"
    cidr_block =  "${var.external_cidr}"
    from_port = "${var.port_in_pri_acl_from}" /* should normally be 443 */
    to_port = "${var.port_in_pri_acl_to}" /* same here 443 */
}

resource "aws_network_acl_rule" "out_pri" {
    count = "${var.add_out_pri_acl}"

    network_acl_id = "${var.local_network_private_acls}"
    egress = true
    protocol = "tcp"
    rule_number = "${var.acl_rule_number}"
    rule_action = "allow"
    cidr_block =  "${var.external_cidr}"
    from_port = "${var.port_out_pri_acl_from}" /* efimerals 1024 */
    to_port = "${var.port_out_pri_acl_to}" /* 65535 */
}

/* Add the Public Network ACL for the new routes */
resource "aws_network_acl_rule" "in_public" {
    count = "${var.add_in_pub_acl}"

    network_acl_id = "${var.local_network_public_acls}"
    egress = false
    protocol = "tcp"
    rule_number = "${var.acl_rule_number}"
    rule_action = "allow"
    cidr_block =  "${var.external_cidr}"
    from_port = "${var.port_in_pub_acl_from}" /* normally 22 from admin */
    to_port = "${var.port_in_pub_acl_to}"  /* same here 22 */
}
