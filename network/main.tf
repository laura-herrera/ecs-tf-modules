# Partner Cluster VPC
resource "aws_vpc" "default" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags {
    Name = "${var.cluster_name}-${var.environment}"
    Partner = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

/* Internet gateway for the public subnet */
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "${aws_vpc.default.tags.Name}"
    Partner = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

/* Public subnet */
resource "aws_subnet" "public" {
  count = "${var.availability_zone_count}"

  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "${lookup(var.public_subnet_cidrs, count.index)}"
  availability_zone = "${lookup(var.availability_zones, count.index)}"
  map_public_ip_on_launch = false
  depends_on = ["aws_internet_gateway.default"]

  tags {
    Name = "${var.cluster_name}-${var.environment}-pub-${lookup(var.availability_zones, count.index)}"
    Partner = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

/* Routing table for public subnet */
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.default.id}"
  tags {
    Name = "${var.cluster_name}-${var.environment}-rt"
    Partner = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

resource "aws_route" "pub_out" {
    route_table_id = "${aws_route_table.public.id}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
    depends_on = ["aws_route_table.public"]
}

/* Associate the routing table to public subnet */
resource "aws_route_table_association" "public" {
  count = "${var.availability_zone_count}"

  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

/* NAT gateway for private subnets */
resource "aws_eip" "nat_ip" {
  count = "${var.availability_zone_count}"
  vpc = true
}

resource "aws_nat_gateway" "nat_gw" {
  count = "${var.availability_zone_count}"
  allocation_id = "${element(aws_eip.nat_ip.*.id, count.index)}"
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  tags {
    Name = "${var.cluster_name}-${var.environment}-nat-gw"
    Partner = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

/* Private subnet */
resource "aws_subnet" "private" {
  count = "${var.availability_zone_count}"

  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "${lookup(var.private_subnet_cidrs, count.index)}"
  availability_zone = "${lookup(var.availability_zones, count.index)}"
  map_public_ip_on_launch = false
  tags {
    Name = "${var.cluster_name}-${var.environment}-private-${lookup(var.availability_zones, count.index)}"
    Partner = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

/* Routing table for private subnet */
resource "aws_route_table" "private" {
  count = "${var.availability_zone_count}"

  vpc_id = "${aws_vpc.default.id}"
  tags {
    Name = "${var.cluster_name}-${var.environment}-rt"
    Partner = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

resource "aws_route" "priv_out" {
  count = "${var.availability_zone_count}"

  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${element(aws_nat_gateway.nat_gw.*.id, count.index)}"
  depends_on = ["aws_route_table.private"]
}

/* Associate the routing table to private subnet */
resource "aws_route_table_association" "private" {
  count = "${var.availability_zone_count}"

  subnet_id = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

resource "aws_vpc_dhcp_options" "default" {
  domain_name = "${var.internal_domain_aws}"
  domain_name_servers = ["AmazonProvidedDNS"]
  tags {
    Name = "${aws_vpc.default.tags.Name}"
    Partner = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

resource "aws_vpc_dhcp_options_association" "default" {
  vpc_id = "${aws_vpc.default.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.default.id}"
}

/* Default security group */
resource "aws_security_group" "default" {
  name = "${var.cluster_name}-${var.environment}-default"
  description = "Default security group that allows inbound and outbound traffic from all instances in the VPC"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    self = true
  }

  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    self = true
  }

  tags {
    Name = "${var.cluster_name}-${var.environment}-default"
    Partner = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

/* Public Subnet security group */
resource "aws_security_group" "public" {
  name = "${var.cluster_name}-${var.environment}-public"
  description = "Security group for the public instances in the VPC"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 1024
    to_port = 65535
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.cluster_name}-${var.environment}-public"
    Partner = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

/* Private subnet InstanceSecurityGroup */
resource "aws_security_group" "private" {
  name = "${var.cluster_name}-${var.environment}-private"
  description = "Container Instance Allowed Ports"
  vpc_id = "${aws_vpc.default.id}"
  tags {
    Name = "${var.cluster_name}-${var.environment}-private-sg"
    Partner = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

resource "aws_security_group_rule" "in_rules" {
  type = "ingress"
  from_port = 0
  to_port = 65535
  protocol = "tcp"
  cidr_blocks = ["${var.vpc_cidr}"]
  security_group_id = "${aws_security_group.private.id}"
}

resource "aws_security_group_rule" "in_ntp" {
  type = "ingress"
  from_port = 1024
  to_port = 65535
  protocol = "udp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.private.id}"
}

resource "aws_security_group_rule" "out_rules" {
 type = "egress" 
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.private.id}"
}  
