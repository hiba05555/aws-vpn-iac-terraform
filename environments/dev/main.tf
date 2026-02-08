module "vpn" {
  source = "../../modules/vpn"

  name      = "dev"
  vpc_id    = module.network.vpc_id
  subnet_id = module.network.private_subnet_ids[0]

  client_cidr_block = var.vpn_client_cidr_block
  vpc_cidr_block    = "10.0.1.0/24"

  server_certificate_arn            = var.vpn_server_certificate_arn
  client_root_certificate_chain_arn = var.vpn_client_root_certificate_chain_arn

  create_vpc_route = false
  dns_servers      = module.ad.dns_ip_addresses
}

module "network" {
  source = "../../modules/network"

  name                  = "dev"
  cidr_block            = "10.0.0.0/16"
  az_a                  = "us-east-1a"
  az_b                  = "us-east-1b"
  public_subnet_cidr    = "10.0.0.0/24"
  private_subnet_cidr_a = "10.0.1.0/24"
  private_subnet_cidr_b = "10.0.2.0/24"

  ad_domain_name = var.ad_domain_name
  ad_dns_servers = module.ad.dns_ip_addresses

  vpn_client_cidr_block  = var.vpn_client_cidr_block
  vpn_association_eni_id = var.vpn_association_eni_id
}


module "ad" {
  source = "../../modules/ad"

  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.private_subnet_ids
  ad_domain_name    = var.ad_domain_name
  ad_admin_password = var.ad_admin_password

}




