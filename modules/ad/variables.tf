variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "ad_domain_name" {
  type = string
}

variable "ad_admin_password" {
  type      = string
  sensitive = true
}

