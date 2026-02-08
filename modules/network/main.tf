# -------------------------------
# VPC: main private network boundary for all subnets/resources
# DNS is enabled so instances can resolve domain names (required for AD + many AWS services)
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = var.name }
}

# -------------------------------
# Public Subnet (AZ A): hosts internet-facing resources 
# map_public_ip_on_launch=true auto-assigns a public IP to instances launched here
resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.az_a
  map_public_ip_on_launch = true

  tags = { Name = "${var.name}-public-1a" }
}

# -------------------------------
# Internet Gateway: allows the VPC to communicate with the internet
# Needed for public subnets and for NAT Gateway to reach the internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-igw" }
}

# -------------------------------
# Public Route Table: sends all non-VPC traffic (0.0.0.0/0) to the Internet Gateway
# Note: AWS automatically includes the VPC CIDR -> local route for internal subnet-to-subnet traffic
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "${var.name}-public" }
}

# -------------------------------
# Public Route Table Association: attaches the public route table to the public subnet
# This makes the subnet "public" (internet-routable) at the routing level
resource "aws_route_table_association" "public_assoc" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public_1a.id
}

# -------------------------------
# Elastic IP for NAT Gateway: static public IPv4 address used by the NAT Gateway
# Allows private subnet instances to access the internet without being directly exposed
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags   = { Name = "${var.name}-nat-eip" }
}

# -------------------------------
# NAT Gateway: provides outbound internet access for private subnets
# Placed in a public subnet and uses an EIP for internet connectivity
resource "aws_nat_gateway" "ngw" {
  subnet_id     = aws_subnet.public_1a.id
  allocation_id = aws_eip.nat_eip.id

  tags = { Name = "${var.name}-ngw" }

  depends_on = [aws_internet_gateway.igw]
}

# -------------------------------
# Private Subnet (AZ A): hosts internal resources (ex: AD, databases, app servers)
# No public IPs by default; outbound internet goes through the NAT Gateway
resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidr_a
  availability_zone = var.az_a

  tags = { Name = "${var.name}-private-1a" }
}

# -------------------------------
# Private Subnet (AZ B): second private subnet for multi-AZ redundancy/high availability
resource "aws_subnet" "private_1b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidr_b
  availability_zone = var.az_b

  tags = { Name = "${var.name}-private-1b" }
}

# -------------------------------
# Private Route Table: routes internet-bound traffic from private subnets to the NAT Gateway
# Instances remain private but can download updates and reach external services
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }

  tags = { Name = "${var.name}-private" }
}

# -------------------------------
# Private Route Table Association (AZ A): applies private routing rules to private subnet 1a
resource "aws_route_table_association" "private_assoc_a" {
  route_table_id = aws_route_table.private_rt.id
  subnet_id      = aws_subnet.private_1a.id
}

# -------------------------------
# Private Route Table Association (AZ B): applies the same private routing rules to private subnet 1b
resource "aws_route_table_association" "private_assoc_b" {
  route_table_id = aws_route_table.private_rt.id
  subnet_id      = aws_subnet.private_1b.id
}

resource "aws_network_acl" "private_nacl" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-private-nacl"
  }
}

resource "aws_network_acl_association" "private_a" {
  network_acl_id = aws_network_acl.private_nacl.id
  subnet_id      = aws_subnet.private_1a.id
}

resource "aws_network_acl_association" "private_b" {
  network_acl_id = aws_network_acl.private_nacl.id
  subnet_id      = aws_subnet.private_1b.id
}

resource "aws_network_acl_rule" "in_http" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpn_client_cidr_block
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "in_https" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpn_client_cidr_block
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "in_rdp" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpn_client_cidr_block
  from_port      = 3389
  to_port        = 3389
}

resource "aws_network_acl_rule" "in_ephemeral" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 130
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpn_client_cidr_block
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "in_ephemeral_udp" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 140
  egress         = false
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = var.vpn_client_cidr_block
  from_port      = 1024
  to_port        = 65535
}


resource "aws_network_acl_rule" "out_all" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "in_vpc_all" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 50
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "10.0.0.0/16"
}



# -------------------------------
# DHCP Options for AD: pushes AD DNS + domain suffix to instances via DHCP
# Ensures instances use Domain Controller DNS for domain join and authentication
resource "aws_vpc_dhcp_options" "ad" {
  domain_name         = var.ad_domain_name
  domain_name_servers = var.ad_dns_servers
}

# -------------------------------
# DHCP Options Association: attaches the AD DHCP options set to the VPC
# Makes all new (and renewed) instances in the VPC use the AD DNS/domain settings
resource "aws_vpc_dhcp_options_association" "ad" {
  vpc_id          = aws_vpc.this.id
  dhcp_options_id = aws_vpc_dhcp_options.ad.id
}
