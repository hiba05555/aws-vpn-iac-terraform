resource "aws_security_group" "sg_iis" {
  name        = "sg_iis"
  description = "IIS EC2"
  vpc_id      = var.vpc_id

  # NOTE: ping (ICMP) can’t be restricted by source SG in AWS.
  # Keep CIDR for ICMP (optional for debugging).
  ingress {
    description = "ICMP (ping) from VPN clients (optional)"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpn_cidr] 
  }

  ingress {
    description     = "HTTP from Client VPN"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.vpn_sg_id]
  }

  ingress {
    description     = "HTTPS from Client VPN (optional)"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.vpn_sg_id]
  }

  ingress {
    description     = "RDP from Client VPN (optional)"
    from_port       = 3389
    to_port         = 3389
    protocol        = "tcp"
    security_groups = [var.vpn_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "sg_iis" }
}


data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_ssm_role" {
  name               = "${var.name}-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.name}-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

data "aws_ami" "windows_2022" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }
}


resource "aws_instance" "iis" {
  ami                         = data.aws_ami.windows_2022.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.sg_iis.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = false

  user_data = var.user_data

  tags = { Name = var.name }
}

resource "aws_ssm_document" "domain_join" {
  name          = "${var.name}-domain-join"
  document_type = "Command"

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Join Windows instance to AD domain"
    parameters    = {}
    mainSteps = [
      {
        action = "aws:runPowerShellScript"
        name   = "joinDomain"
        inputs = {
          runCommand = [
            "$ErrorActionPreference = 'Stop'",
            "$domain = '${var.ad_domain_name}'",
            "$user   = '${var.ad_join_user}'",
            "$pass   = '${var.ad_join_pass}'",
            "$secpass = ConvertTo-SecureString $pass -AsPlainText -Force",
            "$cred = New-Object System.Management.Automation.PSCredential (\"$domain\\$user\", $secpass)",
            "Add-Computer -DomainName $domain -Credential $cred -Force",
            "Restart-Computer -Force"
          ]
        }
      }
    ]
  })
}

resource "aws_ssm_association" "join_domain" {
  name = aws_ssm_document.domain_join.name

  targets {
    key    = "InstanceIds"
    values = [aws_instance.iis.id]
  }
}


