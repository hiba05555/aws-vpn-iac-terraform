output "directory_id" {
  value = aws_directory_service_directory.mmad.id
}

output "dns_ip_addresses" {
  value = aws_directory_service_directory.mmad.dns_ip_addresses
}
