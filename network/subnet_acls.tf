/* Public Subnets ACLs */
resource "aws_network_acl" "public_subnet" {
  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = ["${aws_subnet.public.*.id}"]

  tags {
    Name = "${var.cluster_name}-${var.environment}-public"
    Cluster = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

/* Inbound Rules */
resource "aws_network_acl_rule" "in_pub_100" {
    network_acl_id = "${aws_network_acl.public_subnet.id}"
    egress = false
    protocol = "tcp"
    rule_number = 100
    rule_action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 80
    to_port = 80
}

resource "aws_network_acl_rule" "in_pub_101" {
    network_acl_id = "${aws_network_acl.public_subnet.id}"
    egress = false
    protocol = "tcp"
    rule_number = 101
    rule_action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 443
    to_port = 443
}

resource "aws_network_acl_rule" "in_pub_102" {
    network_acl_id = "${aws_network_acl.public_subnet.id}"
    egress = false
    protocol = "udp"
    rule_number = 102
    rule_action = "allow"
    cidr_block =  "${aws_vpc.default.cidr_block}"
    from_port = 123
    to_port = 123
}

resource "aws_network_acl_rule" "in_pub_200" {
    network_acl_id = "${aws_network_acl.public_subnet.id}"
    egress = false
    protocol = "tcp"
    rule_number = 200
    rule_action = "allow"
    cidr_block =  "${aws_vpc.default.cidr_block}"
    from_port = 0
    to_port = 1024
}

resource "aws_network_acl_rule" "in_pub_201" {
    network_acl_id = "${aws_network_acl.public_subnet.id}"
    egress = false
    protocol = "tcp"
    rule_number = 201
    rule_action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
}

resource "aws_network_acl_rule" "in_pub_202" {
    network_acl_id = "${aws_network_acl.public_subnet.id}"
    egress = false
    protocol = "udp"
    rule_number = 202
    rule_action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
}
 
/* Outbound Rules */
resource "aws_network_acl_rule" "out_pub_100" {
    network_acl_id = "${aws_network_acl.public_subnet.id}"
    egress = true
    protocol = "tcp"
    rule_number = 100
    rule_action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 80
    to_port = 80
}

resource "aws_network_acl_rule" "out_pub_101" {
    network_acl_id = "${aws_network_acl.public_subnet.id}"
    egress = true
    protocol = "tcp"
    rule_number = 101
    rule_action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 443
    to_port = 443
}

resource "aws_network_acl_rule" "out_pub_102" {
    network_acl_id = "${aws_network_acl.public_subnet.id}"
    egress = true
    protocol = "udp"
    rule_number = 103
    rule_action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 123
    to_port = 123
}

resource "aws_network_acl_rule" "out_pub_110" {
    network_acl_id = "${aws_network_acl.public_subnet.id}"
    egress = true
    protocol = "tcp"
    rule_number = 110
    rule_action = "allow"
    cidr_block = "${aws_vpc.default.cidr_block}"
    from_port = 0
    to_port = 1024
}

resource "aws_network_acl_rule" "out_pub_200" {
    network_acl_id = "${aws_network_acl.public_subnet.id}"
    egress = true
    protocol = "tcp"
    rule_number = 200
    rule_action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
}

resource "aws_network_acl_rule" "out_pub_300" {
    network_acl_id = "${aws_network_acl.public_subnet.id}"
    egress = true
    protocol = "udp"
    rule_number = 300
    rule_action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
}

/* Private Subnets ACLs */
resource "aws_network_acl" "private_subnet" {
  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = ["${aws_subnet.private.*.id}"]

  tags {
    Name = "${var.cluster_name}-${var.environment}"
    Cluster = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

/* Inbound Rules */
resource "aws_network_acl_rule" "in_pri_100" {
    network_acl_id = "${aws_network_acl.private_subnet.id}"
    egress = false
    protocol = "udp"
    rule_number = 100
    rule_action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 123
    to_port = 123
}

resource "aws_network_acl_rule" "in_pri_200" {
    network_acl_id = "${aws_network_acl.private_subnet.id}"
    egress = false
    protocol = "tcp"
    rule_number = 200
    rule_action = "allow"
    cidr_block =  "${aws_vpc.default.cidr_block}"
    from_port = 0
    to_port = 65535
}

resource "aws_network_acl_rule" "in_pri_210" {
    network_acl_id = "${aws_network_acl.private_subnet.id}"
    egress = false
    protocol = "tcp"
    rule_number = 210
    rule_action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
}

resource "aws_network_acl_rule" "in_pri_220" {
    network_acl_id = "${aws_network_acl.private_subnet.id}"
    egress = false
    protocol = "udp"
    rule_number = 220
    rule_action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
}

/* Outbound Rules */
resource "aws_network_acl_rule" "out_pri_100" {
    network_acl_id = "${aws_network_acl.private_subnet.id}"
    egress =true
    protocol = "tcp"
    rule_number = 100
    rule_action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 80
    to_port = 80
}

resource "aws_network_acl_rule" "out_pri_101" {
    network_acl_id = "${aws_network_acl.private_subnet.id}"
    egress = true
    protocol = "tcp"
    rule_number = 101
    rule_action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 443
    to_port = 443
}

resource "aws_network_acl_rule" "out_pri_102" {
    network_acl_id = "${aws_network_acl.private_subnet.id}"
    egress = true
    protocol = "udp"
    rule_number = 103
    rule_action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 123
    to_port = 123
}

resource "aws_network_acl_rule" "out_pri_200" {
    network_acl_id = "${aws_network_acl.private_subnet.id}"
    egress = true
    protocol = "tcp"
    rule_number = 200
    rule_action = "allow"
    cidr_block =  "${aws_vpc.default.cidr_block}"
    from_port = 0
    to_port = 65535
}

