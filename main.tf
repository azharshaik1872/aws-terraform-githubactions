provider "aws" {
  region     = "us-east-1"
}

#1.Create VPC
resource "aws_vpc" "lab" {
  cidr_block       = "10.0.0.0/16"
    tags = {
    Name = "Lab VPC"
  }
}

#2.Create IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.lab.id

  tags = {
    Name = "Lab IGW"
  }
}
#3.Create Custom RT
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Lab RT"
  }
}

#4.Create Subnet
resource "aws_subnet" "subnet01" {
  vpc_id     = aws_vpc.lab.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1c"
  
  tags = {
    Name = "Lab Subnet01"
  }
}

#5.Associate Subnet with RT
resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.subnet01.id
  route_table_id = aws_route_table.rt.id
}
#6.Create SG to allow port 22,80,443
resource "aws_security_group" "labsg" {
  name        = "labsg"
  description = "Allow 22,80,443 inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.lab.id

  tags = {
    Name = "labsg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "port22" {
  security_group_id = aws_security_group.labsg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "port80" {
  security_group_id = aws_security_group.labsg.id
  cidr_ipv4         ="0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "port443" {
  security_group_id = aws_security_group.labsg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "outbound" {
  security_group_id = aws_security_group.labsg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#7.Create NIC with IP in Subnet we created.
resource "aws_network_interface" "nic" {
  subnet_id       = aws_subnet.subnet01.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.labsg.id]

}
#8.Create EC2 with Apache installed
resource "aws_instance" "labinstance01" {
  ami           = "ami-0554aa6767e249943"
  instance_type = "t2.micro"
  availability_zone = "us-east-1c"
  #associate_public_ip_address = "true"
  key_name = "MyTFLab"

  tags = {
    Name = "labinstance01"
  }

  network_interface {
    network_interface_id = aws_network_interface.nic.id
    device_index         = 0
  }

  user_data = <<-EOF
                #! /bin/bash
                sudo yum update -y
                sudo yum install httpd -y
                sudo systemctl start httpd
                sudo systemctl enable httpd
                sudo bash -c 'echo Your First TFCode is Successfull > /var/www/html/index.html'
                EOF
                 
}

resource "aws_eip" "labeip" {
  domain = "vpc"
  network_interface         = aws_network_interface.nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [ aws_internet_gateway.igw ]
}
