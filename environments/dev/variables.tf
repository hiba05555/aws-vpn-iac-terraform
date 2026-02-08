variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type    = string
  default = "default"
}

variable "ad_domain_name" {
  type    = string
  default = "corp.internal"
}

variable "ad_admin_password" {
  type      = string
  sensitive = true
}

# AWS Client VPN - server cert (ACM)
variable "vpn_server_certificate_arn" {
  type = string
}

# AWS Client VPN - client root chain/CA cert (ACM)
variable "vpn_client_root_certificate_chain_arn" {
  type = string
}

# CIDR donné aux clients VPN (ne doit pas overlap le VPC)
variable "vpn_client_cidr_block" {
  type    = string
  default = "10.100.0.0/22"
}

# CIDR autorisé dans SG de l'EC2 (doit matcher vpn_client_cidr_block)
variable "vpn_cidr" {
  type    = string
  default = "10.100.0.0/22"
}

variable "vpn_association_eni_id" {
  type = string
}

