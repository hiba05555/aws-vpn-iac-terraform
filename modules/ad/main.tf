resource "aws_security_group" "sg_ad" {
  name        = "sg_ad"
  description = "Allow EC2 IIS to talk to Managed AD"
  vpc_id      = var.vpc_id

  # DNS
  ingress {
    from_port       = 53
    to_port         = 53
    protocol        = "tcp"
  }

  ingress {
    from_port       = 53
    to_port         = 53
    protocol        = "udp"
  }

  # Kerberos
  ingress {
    from_port       = 88
    to_port         = 88
    protocol        = "tcp"
  }

  ingress {
    from_port       = 88
    to_port         = 88
    protocol        = "udp"
  }

  # LDAP / LDAPS
  ingress {
    from_port       = 389
    to_port         = 389
    protocol        = "tcp"
  }

  ingress {
    from_port       = 389
    to_port         = 389
    protocol        = "udp"
  }

  ingress {
    from_port       = 636
    to_port         = 636
    protocol        = "tcp"
  }

  # SMB
  ingress {
    from_port       = 445
    to_port         = 445
    protocol        = "tcp"
  }

  # RPC
  ingress {
    from_port       = 135
    to_port         = 135
    protocol        = "tcp"
  }

  ingress {
    from_port       = 49152
    to_port         = 65535
    protocol        = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "sg-ad" }
}

resource "aws_directory_service_directory" "mmad" {
  name     = var.ad_domain_name
  password = var.ad_admin_password
  type     = "MicrosoftAD"
  edition  = "Standard"

  vpc_settings {
    vpc_id     = var.vpc_id
    subnet_ids = var.subnet_ids
  }

  tags = { Name = "mmad" }
}
