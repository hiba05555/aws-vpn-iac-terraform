variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "vpn_cidr" {
  type  = string
  default = "10.100.0.0/22"
}
variable "vpn_sg_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "name" {
  type = string
}

variable "user_data" {
  type    = string
  default = null
}

variable "ad_domain_name" {
  type = string
}

variable "ad_join_user" {
  type = string
}

variable "ad_join_pass" {
  type      = string
  sensitive = true
}
