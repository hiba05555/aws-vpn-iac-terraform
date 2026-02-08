variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "client_cidr_block" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "server_certificate_arn" {
  type = string
}

# REQUIRED for mutual TLS (client certs signed by this chain)
variable "client_root_certificate_chain_arn" {
  type = string
}

variable "dns_servers" {
  type    = list(string)
  default = []
}

variable "enable_logging" {
  type    = bool
  default = true
}

variable "log_group_name" {
  type    = string
  default = null
}

variable "log_stream_name" {
  type    = string
  default = null
}

variable "create_vpc_route" {
  type    = bool
  default = false
}
