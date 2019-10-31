/* External ApplicationLoadBalancerSecurityGroup */
resource "aws_security_group" "external_alb" {
  name = "${var.cluster_name}-${var.environment}-alb"
  description = "Application Load Balancer Allowed Ports"
  vpc_id = "${var.default_vpc}"

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.cluster_name}-${var.environment}"
    Cluster = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

/* S3 bucket for External ALB logs */
resource "aws_s3_bucket" "alb_logs" {
  bucket = "${var.cluster_name}-${var.environment}-logs"
  acl = "private"

  tags {
    Name = "${var.cluster_name}-${var.environment}"
    Cluster = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

/* External ApplicationLoadBalancer */
resource "aws_alb" "external_alb" {
  name = "${var.cluster_name}-${var.environment}"
  internal = "${var.alb_external}" 
  security_groups = ["${aws_security_group.external_alb.id}"]
  subnets = ["${var.public_subnets}"]

  enable_deletion_protection = false 

  tags {
    Name  = "${var.cluster_name}-${var.environment}"
    Cluster = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

resource "aws_alb_listener" "frontend_80" {
  load_balancer_arn = "${aws_alb.external_alb.arn}"
  port = "80"
  protocol = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.backend.arn}"
    type = "forward"
  }
}

/* Create a listener with given SSL cert */
resource "aws_alb_listener" "frontend_443" {
  load_balancer_arn = "${aws_alb.external_alb.arn}"
  port = "443"
  protocol = "HTTPS"
  ssl_policy = "${var.ssl_external_security_policy}"
  certificate_arn = "${var.ssl_cert_external_domain}"

  default_action {
    target_group_arn = "${aws_alb_target_group.backend.arn}"
    type = "forward"
  }
}

resource "aws_alb_target_group" "backend" {
  name = "backend-${var.cluster_name}-${var.environment}"
  port = "${var.port_btg}"
  protocol = "${var.protocol_btg}"
  vpc_id  = "${var.default_vpc}"

  health_check {
    healthy_threshold = "${var.healthy_threshold_btg_hc}"
    unhealthy_threshold = "${var.unhealthy_threshold_btg_hc}"
    path = "${var.path_btg_hc}"
    protocol = "${var.protocol_btg_hc}"
    interval = "${var.interval_btg_hc}"
    timeout = "${var.timeout_btg_hc}"
    matcher = "200"
  }

  tags {
    Name  = "${var.cluster_name}-${var.environment}"
    Cluster = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

/* Internal ApplicationLoadBalancerSecurityGroup */
resource "aws_security_group" "internal_alb" {
  name = "${var.cluster_name}-${var.environment}-int-alb"
  description = "Internal Application Load Balancer Allowed Ports"
  vpc_id = "${var.default_vpc}"

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.cluster_name}-${var.environment}"
    Cluster = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

/* Internal ApplicationLoadBalancer */
resource "aws_alb" "internal_alb" {
  name = "${var.cluster_name}-${var.environment}-internal"
  internal = "${var.alb_internal}"
  security_groups = ["${aws_security_group.internal_alb.id}"]
  subnets = ["${var.private_subnets}"]

  enable_deletion_protection = false

  tags {
    Name  = "${var.cluster_name}-${var.environment}"
    Cluster = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

resource "aws_alb_listener" "internal_80" {
  load_balancer_arn = "${aws_alb.internal_alb.arn}"
  port = "80"
  protocol = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.default_svc.arn}"
    type = "forward"
  }
}

resource "aws_alb_listener" "internal_443" {
  load_balancer_arn = "${aws_alb.internal_alb.arn}"
  port = "443"
  protocol = "HTTPS"
  ssl_policy = "${var.ssl_internal_security_policy}"
  certificate_arn = "${var.ssl_cert_internal_domain}"

  default_action {
    target_group_arn = "${aws_alb_target_group.default_svc.arn}"
    type = "forward"
  }
}

resource "aws_alb_target_group" "default_svc" {
  name = "default-${var.cluster_name}-${var.environment}"
  port = 80
  protocol = "HTTP"
  vpc_id = "${var.default_vpc}"

  health_check {
    healthy_threshold = 5
    unhealthy_threshold = 10
    path = "/"
    protocol = "HTTP"
    interval = 30
    timeout = 5
    matcher = "200"
  }

  tags {
    Name  = "${var.cluster_name}-${var.environment}"
    Cluster = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

/* InstanceRole */
resource "aws_iam_role" "ecs" {
  name = "${var.cluster_name}-${var.environment}-instance"
  path = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [ "ec2.amazonaws.com" ]
      },
      "Action": [ "sts:AssumeRole" ]
    }
  ]
}
EOF
}

/* InstancePolicies */
resource "aws_iam_role_policy" "ecs" {
  name = "${var.cluster_name}-${var.environment}-instance"
  role = "${aws_iam_role.ecs.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::private/Docker/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "elasticloadbalancing:*",
        "ecs:*",
        "iam:ListInstanceProfiles",
        "iam:ListRoles",
        "iam:PassRole",
        "iam:UploadServerCertificate",
        "iam:DeleteServerCertificate",
        "route53:*"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

/* Instance Role Policies Attachments  */
resource "aws_iam_role_policy_attachment" "SSM-attach" {
    role = "${aws_iam_role.ecs.name}"
    policy_arn = "${var.SSM_policy}"
}
resource "aws_iam_role_policy_attachment" "ECR-RO-attach" {
    role = "${aws_iam_role.ecs.name}"
    policy_arn = "${var.ECR_RO_policy}"
}
resource "aws_iam_role_policy_attachment" "CW-LOGS-attach" {
    role = "${aws_iam_role.ecs.name}"
    policy_arn = "${var.CW_LOGS_policy}"
}
resource "aws_iam_role_policy_attachment" "ECS-attach" {
    role = "${aws_iam_role.ecs.name}"
    policy_arn = "${var.ECS_policy}"
}
resource "aws_iam_role_policy_attachment" "CW-CM-attach" {
    role = "${aws_iam_role.ecs.name}"
    policy_arn = "${var.CW_CM_policy}"
}

/* ServiceRole */
resource "aws_iam_role" "svc_role" {
  name = "${var.cluster_name}-${var.environment}-svc"
  path = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [ "ecs.amazonaws.com" ]
      },
      "Action": [ "sts:AssumeRole" ]
    }
  ]
}
EOF
}

/* ServiceRolePolicies */
resource "aws_iam_role_policy" "svc_policy" {
  name = "${var.cluster_name}-${var.environment}-svc"
  role = "${aws_iam_role.svc_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "elasticloadbalancing:*",
        "ecs:*",
        "iam:ListInstanceProfiles",
        "iam:ListRoles",
        "iam:PassRole",
        "route53:*"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

/* InstanceProfile */
resource "aws_iam_instance_profile" "ecs" {
  name = "${var.cluster_name}-${var.environment}-instance"
  path = "/"
  role = "${aws_iam_role.ecs.name}"
}

/* LaunchConfiguration */
data "template_file" "template_ecs" {
  template = "${file("files/ecs.sh")}"
  vars {
    cluster = "${aws_ecs_cluster.default.name}"
    registry = "${var.docker_registry}"
  }
}

resource "aws_launch_configuration" "ecs" {
  name_prefix = "${var.cluster_name}-${var.environment}"
  key_name = "${var.key_name}"
  image_id = "${lookup(var.ecs_amis, var.availability_zones[count.index])}"
  instance_type = "${var.ecs_instance_type}"
  security_groups = ["${var.private_sg}"]
  iam_instance_profile = "${aws_iam_instance_profile.ecs.name}"
  associate_public_ip_address = false
  user_data = "${data.template_file.template_ecs.rendered}"
  lifecycle {
    create_before_destroy = true
  }
}

/* AutoScalingGroup */
resource "aws_autoscaling_group" "ecs" {
  name = "${var.cluster_name}-${var.environment}"
  vpc_zone_identifier = ["${var.private_subnets}"]
  availability_zones = ["${var.private_az}"]
  min_size = "${var.min_size}"
  max_size = "${var.max_size}"
  desired_capacity = "${var.desired_capacity}"
  default_cooldown = "${var.default_cooldown}"
  health_check_type = "EC2"
  health_check_grace_period = "${var.health_check_grace_period}"
  enabled_metrics = ["${var.enabled_metrics}"]
  launch_configuration = "${aws_launch_configuration.ecs.name}"
  lifecycle {
    create_before_destroy = true
    ignore_changes = ["launch_configuration"]
  }

  tags = [
    {
      key = "Name"
      value = "${var.cluster_name}-${var.environment}"
      propagate_at_launch = true
    },
    {
      key = "${var.enable_autopatch ? "Autopatch" : "False"}"
      value = "ecs.${var.region}"
      propagate_at_launch = false
    },
    {
      key = "Cluster Name"
      value = "${var.cluster_name}"
      propagate_at_launch = true
    },
    {
      key = "Environment"
      value = "${var.environment}"
      propagate_at_launch = true
    }
  ]
}

resource "aws_autoscaling_policy" "scale_out" {
  name = "shared-scale-out"
  autoscaling_group_name = "${aws_autoscaling_group.ecs.name}"
  policy_type = "StepScaling"
  adjustment_type = "ChangeInCapacity"
  step_adjustment {
    scaling_adjustment = 1
    metric_interval_upper_bound = -1
  }
}

resource "aws_autoscaling_policy" "scale_in" {
  name = "shared-scale-in"
  autoscaling_group_name = "${aws_autoscaling_group.ecs.name}"
  policy_type = "StepScaling"
  adjustment_type = "ChangeInCapacity"
  step_adjustment {
    scaling_adjustment = -1
    metric_interval_lower_bound = 1
  }
}

resource "aws_autoscaling_lifecycle_hook" "draining" {
  name = "ASGECSTerminateHook"
  autoscaling_group_name = "${aws_autoscaling_group.ecs.name}"
  default_result = "ABANDON"
  heartbeat_timeout = 900
  lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"

  notification_target_arn = "${var.notification_topic}"
  role_arn = "${var.SNS_role}"
}

/* Cluster */
resource "aws_ecs_cluster" "default" {
  name = "${var.cluster_name}-${var.environment}"
}

resource "aws_route53_record" "external" {
  zone_id = "${var.public_zone}"
  name = "${aws_ecs_cluster.default.name}-${var.region}"
  type = "A"

  alias {
    name = "${aws_alb.external_alb.dns_name}"
    zone_id = "${aws_alb.external_alb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "internal" {
  zone_id = "${var.private_zone}"
  name = "${aws_ecs_cluster.default.name}-${var.region}"
  type = "A"

  alias {
    name = "${aws_alb.internal_alb.dns_name}"
    zone_id = "${aws_alb.internal_alb.zone_id}"
    evaluate_target_health = true
  }
}

/* Auto Patching */
resource "aws_autoscaling_policy" "outdated_instances" {
  count = "${var.enable_autopatch ? 1 : 0}"

  name = "shared-outdated-instances"
  autoscaling_group_name = "${aws_autoscaling_group.ecs.name}"
  policy_type = "StepScaling"
  adjustment_type = "ChangeInCapacity"
  step_adjustment {
    scaling_adjustment = 1
    metric_interval_lower_bound = 0
  }
}
