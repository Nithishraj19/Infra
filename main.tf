#create a Vpc
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  tags = {
    Name = "Prod-VPC"
  }
}

#create Public_Subnet
resource "aws_subnet" "public_Subnet" {
  vpc_id            = aws_vpc.main.id
  count             = length(var.public_subnet_cidr)
  cidr_block        = var.public_subnet_cidr[count.index]
  availability_zone = var.public_subnet_availability_zone[count.index]
  tags = {
    Name = "Public_Subnet-${count.index}"
  }
}

# Create a private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main.id
  count             = length(var.private_subnet_cidr)
  cidr_block        = var.private_subnet_cidr[count.index]
  availability_zone = var.private_az[count.index]
  tags = {
    Name = "Private_Subnet-${count.index}"
  }
}


#create internet_gateway
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Prod-Ig"
  }
}
# Create Nat Gateway
resource "aws_eip" "nat_gateway" {
  vpc = true
}
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public_Subnet[1].id
  tags = {
    "Name" = "Prod-Ngw"
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
  count          = length(aws_subnet.public_Subnet)
  subnet_id      = aws_subnet.public_Subnet[count.index].id
  route_table_id = aws_route_table.Public_rt.id
}

#subnet associate with private route table
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private_subnet)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.Private_rt.id
}

# connect internetgateway with public_rt1
resource "aws_route" "route" {
  route_table_id         = aws_route_table.Public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}
# connect with natgateway with 
resource "aws_route" "route1" {
  route_table_id         = aws_route_table.Private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat_gateway.id
  depends_on             = [aws_nat_gateway.nat_gateway]
}

# create my security group for Public_server
resource "aws_security_group" "securitygroup" {
  name        = "public-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "VPC"
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
    Name = "securitygroup"
  }
}
# update security group for ssh
resource "aws_security_group_rule" "inbound" {
  type              = "ingress"
  from_port         = var.inbound_for_ssh_from_port
  to_port           = var.inbound_for_ssh_to_port
  protocol          = "tcp"
  cidr_blocks       = var.incoming_traffic
  security_group_id = aws_security_group.securitygroup.id
}
#update security group for HTTP

resource "aws_security_group_rule" "inbound_for_HTTP" {
  type              = "ingress"
  from_port         = var.inbound_for_HTTP
  to_port           = var.inbound_to_HTTP
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.securitygroup.id
}
resource "aws_security_group_rule" "outbound_for_HTTP" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.securitygroup.id
}

#Create a role 
resource "aws_iam_role" "ec2_access_role" {
  name = "ec2_access_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
      tag-key = "tag-value"
  }
}

# #create an Public_server
resource "aws_instance" "pubic_server" {
  ami           = var.ami_of_Public_server1
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_Subnet[0].id

  associate_public_ip_address = "true"
  vpc_security_group_ids      = [aws_security_group.securitygroup.id]
  key_name                    = var.server1_key_name

  iam_instance_profile {
    name = aws_iam_role.ec2_access_role.name
  }

  tags = {
    Name =  "Public_server"
  }
}

# create my security group for Private_server
resource "aws_security_group" "private-sg" {
  name        = "private-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "VPC"
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
    Name = "private-sg"
  }
}
# update security group for ssh
resource "aws_security_group_rule" "inbound1" {
  type              = "ingress"
  from_port         = var.inbound_for_ssh_from_port
  to_port           = var.inbound_for_ssh_to_port
  protocol          = "tcp"
  cidr_blocks       = var.incoming_traffic
  security_group_id = aws_security_group.private-sg.id
}
#update security group for HTTP

resource "aws_security_group_rule" "inbound_for_HTTP1" {
  type              = "ingress"
  from_port         = var.inbound_for_HTTP
  to_port           = var.inbound_to_HTTP
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.private-sg.id
}
resource "aws_security_group_rule" "outbound_for_HTTP1" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.private-sg.id
}

# #create an Private_server
resource "aws_instance" "private_server" {
  count                       = length(aws_subnet.private_subnet)
  ami                         = var.ami_of_private_server
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private_subnet[count.index].id
  associate_public_ip_address = "false"
  vpc_security_group_ids      = [aws_security_group.private-sg.id]
  key_name                    = var.server1_key_name

  tags = {
    Name = "Private_server-${count.index}"
  }
}



#create another security group for loalbalancer
# create my security group for Private_server
resource "aws_security_group" "securitygroup2" {
  name        = "private-sg1"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "VPC"
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
    Name = "securitygroup2"
  }
}
#target group
resource "aws_lb_target_group" "main" {
  name                          = "targetgroup"
  port                          = 80
  protocol                      = "HTTP"
  vpc_id                        = aws_vpc.main.id
  load_balancing_algorithm_type = "round_robin"
  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    unhealthy_threshold = 2
    healthy_threshold   = 2
    timeout             = 5
  }
}

#attach instance with target group
resource "aws_lb_target_group_attachment" "main" {
  count = length(aws_instance.private_server)
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.private_server[count.index].id
  port             = 80
}

# create a load balancer
resource "aws_lb" "example_alb" {
  name               = "loadbalancer"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.securitygroup2.id]

  subnet_mapping {
    subnet_id = aws_subnet.public_Subnet[0].id
  }
  subnet_mapping {
    subnet_id = aws_subnet.public_Subnet[1].id
  }
}

#Here load_balncer_listener
resource "aws_lb_listener" "example_listener" {
  load_balancer_arn = aws_lb.example_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
