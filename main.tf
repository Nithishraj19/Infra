#create a Vpc
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  tags = {
    Name = "Demo-vpc"
  }
}

#create Public_Subnet
resource "aws_subnet" "public_Subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = var.public_subnet_availability_zone
  tags = {
    Name = "Public_Subnet"
  }
}

# Create a private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main.id
  count = length(var.private_subnet_cidr)
  cidr_block        = var.private_subnet_cidr[count.index]
  availability_zone = var.private_az[count.index]
  tags = {
    Name = "Private_Subnet-${count.index}"
  }
}


#create internet_gateway
resource "aws_internet_gateway" "Demo_ig" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Demo_ig"
  }
}

# Create Nat Gateway
resource "aws_eip" "nat_gateway" {
  vpc = true
}
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public_Subnet.id
  tags = {
    "Name" = "Demo_nat_gateway"
  }
}

#Create Public_route table
resource "aws_route_table" "Public_rt" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Public_rt"
  }
}

# create Private_route_table
resource "aws_route_table" "Private_rt" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Private_rt"
  }
}

#subnet associate with Public route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_Subnet.id
  route_table_id = aws_route_table.Public_rt.id
}

#subnet associate with private route table
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private_subnet)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.Private_rt.id
}
# connect internetgateway with public_rt1
resource "aws_route" "route" {
  route_table_id         = aws_route_table.Public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.Demo_ig.id
}
# connect with natgateway with 
resource "aws_route" "route1" {
  route_table_id         = aws_route_table.Private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat_gateway.id
  depends_on             = [aws_nat_gateway.nat_gateway]
}

# create my security group for Public_server
resource "aws_security_group" "my-sec-group" {
  name        = "public-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "TLS from VPC"
    from_port   = var.inbound_to_HTTP
    to_port     = var.inbound_to_HTTP
    protocol    = "tcp"
  }
  egress {
    from_port = var.egress_from_port
    to_port   = var.egress_to_port
    protocol  = "-1"
  }
  tags = {
    Name = "my-sec-group"
  }
}
# update security group for ssh
resource "aws_security_group_rule" "inbound" {
  type              = "ingress"
  from_port         = var.inbound_for_ssh_from_port
  to_port           = var.inbound_for_ssh_to_port
  protocol          = "tcp"
  cidr_blocks       = var.incoming_traffic
  security_group_id = aws_security_group.my-sec-group.id
}
#update security group for HTTP

resource "aws_security_group_rule" "inbound_for_HTTP" {
  type              = "ingress"
  from_port         = var.inbound_for_HTTP
  to_port           = var.inbound_to_HTTP
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.my-sec-group.id
}
resource "aws_security_group_rule" "outbound_for_HTTP" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.my-sec-group.id
}

# #create an Public_server
resource "aws_instance" "pubic_server" {
  ami                         = var.ami_of_Public_server1
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_Subnet.id
  associate_public_ip_address = "true"
  vpc_security_group_ids      = [aws_security_group.my-sec-group.id]
  key_name                    = var.server1_key_name

  tags = {
    Name = var.name_of_first_server
  }
}

# create my security group for Private_server
resource "aws_security_group" "my-sec-group1" {
  name        = "private-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "TLS from VPC"
    from_port   = var.inbound_to_HTTP
    to_port     = var.inbound_to_HTTP
    protocol    = "tcp"
  }
  egress {
    from_port = var.egress_from_port
    to_port   = var.egress_to_port
    protocol  = "-1"
  }
  tags = {
    Name = "my-sec-group1"
  }
}
# update security group for ssh
resource "aws_security_group_rule" "inbound1" {
  type              = "ingress"
  from_port         = var.inbound_for_ssh_from_port
  to_port           = var.inbound_for_ssh_to_port
  protocol          = "tcp"
  cidr_blocks       = var.incoming_traffic
  security_group_id = aws_security_group.my-sec-group1.id
}
#update security group for HTTP

resource "aws_security_group_rule" "inbound_for_HTTP1" {
  type              = "ingress"
  from_port         = var.inbound_for_HTTP
  to_port           = var.inbound_to_HTTP
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.my-sec-group1.id
}
resource "aws_security_group_rule" "outbound_for_HTTP1" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.my-sec-group1.id
}

# #create an Private_server
resource "aws_instance" "private_server" {
  count = length(aws_subnet.private_subnet)
  ami                         = var.ami_of_private_server
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private_subnet[count.index].id
  associate_public_ip_address = "false"
  vpc_security_group_ids      = [aws_security_group.my-sec-group1.id]
  key_name                    = var.server1_key_name

  tags = {
    Name = var.name_of_private_server[count.index]
  }
}
