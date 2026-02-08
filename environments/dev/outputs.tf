output "vpc_id" {
  value = module.network.vpc_id
}


output "directory_id" {
  value = module.ad.directory_id
}

output "client_vpn_endpoint_id" {
  value = module.vpn.endpoint_id
}

