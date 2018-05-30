variable "cluster_name" {}
variable "environment" {}
variable "vpc_cidr" {}
variable "internal_domain_aws" {}
variable "availability_zones" { type = "map" }
variable "availability_zone_count" {}
variable "public_subnet_cidrs" { type = "map" }
variable "private_subnet_cidrs" { type = "map" }
