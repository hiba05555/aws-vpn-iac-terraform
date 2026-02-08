output "endpoint_id" {
  value = aws_ec2_client_vpn_endpoint.this.id
}

output "cvpn_sg_id" {
  value = aws_security_group.cvpn_sg.id
}


