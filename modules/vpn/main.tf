# SG used by the Client VPN endpoint ENI
resource "aws_security_group" "cvpn_sg" {
  name        = "${var.name}-client-vpn-sg"
  description = "Security group for AWS Client VPN endpoint"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0 #means all ports
    to_port     = 0
    protocol    = "-1" #means all protocols
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = { Name = "${var.name}-client-vpn-sg" }
}

resource "aws_cloudwatch_log_group" "cvpn" {
  count = var.enable_logging ? 1 : 0
  name  = coalesce(var.log_group_name, "/aws/clientvpn/${var.name}")
}

resource "aws_cloudwatch_log_stream" "cvpn" {
  count          = var.enable_logging ? 1 : 0
  name           = coalesce(var.log_stream_name, "connections")
  log_group_name = aws_cloudwatch_log_group.cvpn[0].name
}

resource "aws_ec2_client_vpn_endpoint" "this" {
  description            = "${var.name} Client VPN"
  server_certificate_arn = var.server_certificate_arn
  client_cidr_block      = var.client_cidr_block
  vpc_id                 = var.vpc_id

  transport_protocol = "tcp"
  vpn_port           = 443
  split_tunnel       = true

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = var.client_root_certificate_chain_arn
  }

  security_group_ids = [aws_security_group.cvpn_sg.id]
  dns_servers        = var.dns_servers

  connection_log_options {
    enabled               = var.enable_logging
    cloudwatch_log_group  = var.enable_logging ? aws_cloudwatch_log_group.cvpn[0].name : null
    cloudwatch_log_stream = var.enable_logging ? aws_cloudwatch_log_stream.cvpn[0].name : null
  }

  tags = { Name = "${var.name}-client-vpn" }
}

resource "aws_ec2_client_vpn_network_association" "assoc" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  subnet_id              = var.subnet_id
}

resource "aws_ec2_client_vpn_authorization_rule" "auth_vpc" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  target_network_cidr    = var.vpc_cidr_block
  authorize_all_groups   = true

  depends_on = [aws_ec2_client_vpn_network_association.assoc]
}

resource "aws_ec2_client_vpn_route" "route_vpc" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  destination_cidr_block = var.vpc_cidr_block
  target_vpc_subnet_id   = var.subnet_id

  depends_on = [aws_ec2_client_vpn_network_association.assoc]
}
