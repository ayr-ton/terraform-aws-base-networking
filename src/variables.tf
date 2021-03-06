variable "vpc_cidr" {}
variable "region" {}
variable "availability_zones" {}

variable "component" {}
variable "deployment_identifier" {}
variable "dependencies" {
  default = ""
}

variable "bastion_ami" {}
variable "bastion_instance_type" {
  default = "t2.nano"
}
variable "bastion_ssh_public_key_path" {}
variable "bastion_ssh_allow_cidrs" {}

variable "domain_name" {}
variable "public_zone_id" {}
variable "private_zone_id" {}

variable "include_lifecycle_events" {
  default = "yes"
}
variable "infrastructure_events_bucket" {
  default = ""
}