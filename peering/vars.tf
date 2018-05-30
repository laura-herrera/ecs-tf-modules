variable "cluster_name" {}
variable "environment" {}
variable "az_count" {}
variable "local_vpc" {}
variable "local_cidr" {}
variable "local_sg" {}
variable "local_public_rt" {}
variable "local_private_rts" { type = "list" }
variable "local_network_public_acls" {}
variable "local_network_private_acls" {}
variable "external_vpc" {}
variable "external_cidr" {}
variable "external_rts" { type = "list" }
variable "external_name" {}
variable "add_public_route" {}
variable "sg_port_from" {}
variable "sg_port_to" {}
variable "add_in_pub_acl" {}
variable "port_in_pub_acl_from" {}
variable "port_in_pub_acl_to" {}
variable "add_in_pri_acl" {}
variable "port_in_pri_acl_from" {}
variable "port_in_pri_acl_to" {}
variable "add_out_pri_acl" {}
variable "port_out_pri_acl_from" {}
variable "port_out_pri_acl_to" {}
variable "acl_rule_number" {}
