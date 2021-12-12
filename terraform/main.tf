variable "vpc_id" {}
variable "ssh_ip_list" {}
variable "project_name" {}
variable "instance_type" {}
variable "key_pair_name" {}
variable "ami_id" {}
variable "owner" {}
data "aws_vpc" "selected" {
  id = var.vpc_id
}
