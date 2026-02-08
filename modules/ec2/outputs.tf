output "iis_instance_id" {
  value = aws_instance.iis.id
}

output "iis_private_ip" {
  value = aws_instance.iis.private_ip
}

output "sg_iis_id" {
  value = aws_security_group.sg_iis.id
}

output "instance_id" {
  value = aws_instance.iis.id
}
