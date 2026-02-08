variable "name" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "public_subnet_cidr" {
  type = string
}

variable "az_a" {
  type = string
}

variable "az_b" {
  type = string
}

variable "private_subnet_cidr_a" {
  type = string
}

variable "private_subnet_cidr_b" {
  type = string
}

variable "ad_domain_name" {
  type = string
}

variable "ad_dns_servers" {
  type = list(string)
}

variable "vpn_client_cidr_block" {
  type = string
}

variable "vpn_association_eni_id" {
  type = string
}
