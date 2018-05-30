/* S3 User and permissions to access bucket */
resource "aws_iam_user" "s3_user" {
  count = "${var.create_s3_bucket_user}"
  name = "${var.s3_bucket_name}-S3"
  path = "/"
}

resource "aws_iam_user_policy" "s3_bucket_rw" {
  count = "${var.create_s3_bucket_user}"
  name = "${var.s3_bucket_name}-S3"
  user = "${aws_iam_user.s3_user.name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": "arn:aws:s3:::${var.s3_bucket_name}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "arn:aws:s3:::${var.s3_bucket_name}/*"
            ]
        }
    ]
}
EOF
}

/* S3 bucket */
resource "aws_s3_bucket" "service_bucket" {
  count = "${var.create_s3_bucket}"
  bucket = "${var.s3_bucket_name}"
  acl = "private"

  cors_rule {
    allowed_headers = "${var.cors_allowed_headers}"
    allowed_methods = "${var.cors_allowed_methods}"
    allowed_origins = "${var.cors_allowed_origins}"
    max_age_seconds = 3000
  }

  tags {
    Name = "${var.s3_bucket_name}"
    Cluster = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

/* Postgres DB security group */
resource "aws_security_group" "pgsql_sg" {
  count = "${var.create_db}"
  name = "${var.db_instance_name != "" ? format("%s-db", var.db_instance_name) : format("%s-%s-db-sg", var.service_name,var.environment)}"
  description = "Postgresql allowed traffic"
  vpc_id = "${var.default_vpc}"

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["${var.default_vpc_cidr}"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.service_name}-${var.environment}"
    Cluster = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

/* Create DB Encryption Key from KMS */
resource "aws_kms_key" "db_key" {
  count = "${var.create_db}"
  description = "${var.db_instance_name} ${var.service_name} ${var.environment} DB Encryption Key"
  is_enabled = true
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "key-consolepolicy-3",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::#############:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow access for Key Administrators",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::#############:root"
      },
      "Action": [
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:Delete*",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Allow use of the key",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::#############:root"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Allow attachment of persistent resources",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::#############:root"
      },
      "Action": [
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant"
      ],
      "Resource": "*",
      "Condition": {
        "Bool": {
          "kms:GrantIsForAWSResource": "true"
        }
      }
    }
  ]
}
EOF
}

/* create the DBb */
resource "aws_db_instance" "service_db" {
  count = "${var.create_db}"
  identifier = "${var.db_instance_name != "" ? var.db_instance_name : format("%s-%s", var.service_name,var.environment)}"
  engine = "${var.db_engine_type}"
  engine_version = "${var.db_engine_version}"
  storage_type = "${var.db_storage_type}"
  allocated_storage = "${var.db_storage_size}"
  storage_encrypted = true
  kms_key_id = "${aws_kms_key.db_key.arn}"
  instance_class = "${var.db_instance_class}"
  name = "${var.db_name}"
  username = "${var.db_username}"
  password = "placeholder"
  db_subnet_group_name = "${aws_db_subnet_group.db_sub_group.name}"
  parameter_group_name = "${var.db_parameter_group}"
  vpc_security_group_ids = ["${aws_security_group.pgsql_sg.id}"]
  backup_retention_period = "${var.db_backup_retention_period}"
  backup_window = "${var.db_backup_window}"
  maintenance_window = "${var.db_maintenance_window}"
  multi_az = "${var.db_multi_az}"
  publicly_accessible = "${var.db_public}"

  tags {
    Name = "${var.service_name}-${var.environment}"
    Cluster = "${var.cluster_name}"
    Environment = "${var.environment}"
    Timezone = "${var.timezone}"
    Owner =  "${var.owner}"
    Tool = "${var.tool}"
  }
}

resource "aws_db_subnet_group" "db_sub_group" {
  count = "${var.create_db}"
  name = "${var.db_instance_name != "" ? var.db_instance_name : format("%s-%s-subnetg", var.service_name,var.environment)}"
  description = "Subnet Group for DB ${var.service_name}-${var.environment}"
  subnet_ids = ["${var.private_subnets}"]
}

/* Redis SG */
resource "aws_security_group" "redis_sg" {
  count = "${var.create_redis}"
  name = "${var.redis_name != "" ? format("%s-redis", var.redis_name) : format("%s-%s-redis-sg", var.service_name,var.environment)}"
  description = "ElastiCache allowed traffic"
  vpc_id = "${var.default_vpc}"

  ingress {
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
    cidr_blocks = ["${var.default_vpc_cidr}"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.service_name}-${var.environment}"
    Cluster = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

resource "aws_elasticache_cluster" "service_redis" {
  count = "${var.create_redis}"
  cluster_id = "${var.redis_name != "" ? var.redis_name : format("%s-%s", var.service_name,var.environment)}"
  engine = "redis"
  port = 6379
  num_cache_nodes = 1
  engine_version =  "${var.redis_engine_version}"
  node_type = "${var.redis_node_type}"
  parameter_group_name = "${var.redis_parameter_group}"
  snapshot_window = "${var.redis_backup_window}"
  snapshot_retention_limit = "${var.redis_backup_retention_period}"
  maintenance_window = "${var.redis_maintenance_window}"
  security_group_ids = ["${aws_security_group.redis_sg.id}"]
  subnet_group_name = "${aws_elasticache_subnet_group.redis_sub_group.name}"

  tags {
    Name = "${var.service_name}-${var.environment}"
    Cluster = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

resource "aws_elasticache_subnet_group" "redis_sub_group" {
  count = "${var.create_redis}"
  name  = "${var.redis_name != "" ? var.redis_name : format("%s-%s-subnetg", var.service_name,var.environment)}"
  description = "Subnet Group for ${var.service_name}-${var.environment}"
  subnet_ids = ["${var.private_subnets}"]
}


/* CloudFront Distribution for assets */
resource "aws_cloudfront_distribution" "assets_distribution" {
  count = "${var.create_cf_distribution}"

  origin {
    domain_name = "${var.service_url}.${var.service_domain}"
    origin_id = "${var.service_name}"

    custom_origin_config {
      http_port = "${var.cf_origin_http_port}"
      https_port = "${var.cf_origin_https_port}"
      origin_protocol_policy = "${var.cf_origin_protocol_policy}"
      origin_ssl_protocols = "${var.cf_origin_ssl_protocols}"
      origin_keepalive_timeout = "${var.cf_origin_keepalive_timeout}"
      origin_read_timeout = "${var.cf_origin_read_timeout}"
    }
  }

  enabled = "${var.cf_dist_enabled}"
  is_ipv6_enabled = "${var.cf_dist_ipv6}"
  comment = "Cloud Front for assets ${var.service_name}"
  default_root_object = "${var.cf_dist_root_object}"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.service_name}"

    forwarded_values {
      query_string = "${var.cf_dist_fw_query_string}"
      headers = ["${var.cf_dist_fw_headers}"]
      cookies {
        forward = "${var.cf_dist_fw_cookies}"
      }
    }

    viewer_protocol_policy = "${var.cf_dist_protocol_policy}"
    min_ttl                = "${var.cf_dist_min_ttl}"
    default_ttl            = "${var.cf_dist_default_ttl}"
    max_ttl                = "${var.cf_dist_max_ttl}"
  }

  price_class = "${var.cf_dist_price_class}"

  restrictions {
    geo_restriction {
      restriction_type = "${var.cf_dist_restriction_type}"
      locations        = ["${var.cf_dist_restriction_locations}"]
    }
  }

  tags {
    Name = "${var.service_name}-${var.environment}"
    Cluster = "${var.cluster_name}"
    Environment = "${var.environment}"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
