#defines provider

provider "aws" {
	region = "${var.AWS_REGION}"
}

#defines variables

variable "AWS_REGION" {
	default = "ap-south-1"
}


#VPC

resource "aws_vpc" "prod_vpc" {
	cidr_block = "192.168.0.0/16"
	instance_tenancy = "default"
	enable_dns_support = "true"
	enable_dns_hostnames = "true"
	enable_classiclink = "false"
	tags {
		Name = "prod_vpc"
	}
}

#Subnet 1a public

resource "aws_subnet" "public_subnet_1a" {
	vpc_id = "${aws_vpc.prod_vpc.id}"
	cidr_block = "192.168.1.0/24"
	map_public_ip_on_launch = "true"
	availability_zone = "${var.AWS_REGION}a"
	tags {
		Name = "public_subnet_1a"
	}
}

#Subnet 1a private

resource "aws_subnet" "private_subnet_1a" {
	vpc_id = "${aws_vpc.prod_vpc.id}"
	cidr_block = "192.168.2.0/24"
	map_public_ip_on_launch = "true"
	availability_zone = "${var.AWS_REGION}a"
	tags {
		Name = "private_subnet_1a"
	}
}

#IGW

resource "aws_internet_gateway" "main_igw" {
	vpc_id = "${aws_vpc.prod_vpc.id}"
	tags {
		Name = "main_igw"
	}
}

# Public Route Table 
resource "aws_route_table" "public_route" {
	vpc_id = "${aws_vpc.prod_vpc.id}"
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.main_igw.id}"
	}
	tags {
		Name = "public_route"
	}
}

# Public Route table association
resource "aws_route_table_association" "public_subnet_1a" {
	subnet_id = "${aws_subnet.public_subnet_1a.id}"
	route_table_id = "${aws_route_table.public_route.id}"
} 

#Elastic IP allocation for nat
resource "aws_eip" "nat" {
	vpc      = true
}

# Nat Gateway

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id = "${aws_subnet.private_subnet_1a.id}"

  tags {
    Name = "nat_gw"
  }
}

# Private Route Table 
resource "aws_route_table" "private_route" {
	vpc_id = "${aws_vpc.prod_vpc.id}"
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_nat_gateway.nat_gw.id}"
	}
	tags {
		Name = "private_route"
	}
}

# Private Route table association
resource "aws_route_table_association" "private_subnet_1a" {
	subnet_id = "${aws_subnet.private_subnet_1a.id}"
	route_table_id = "${aws_route_table.private_route.id}"
} 


# Security Group for Bastios Host

resource "aws_security_group" "Bastion-Host-sg" {
	vpc_id = "${aws_vpc.prod_vpc.id}"
	name = "Bastion-Host-sg"
	description = "test-sg"
	egress {
		from_port = 0
		to_port = 0
		protocol = -1
		cidr_blocks = ["0.0.0.0/0"]
	}
	ingress {
		from_port = 3389
		to_port = 3389
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	tags {
		Name = "Bastion-Host-sg"
	}
}

# Security Group for Web Server

resource "aws_security_group" "Web-Server-sg" {
	vpc_id = "${aws_vpc.prod_vpc.id}"
	name = "Web-Server-sg"
	description = "test-sg"
	egress {
		from_port = 0
		to_port = 0
		protocol = -1
		cidr_blocks = ["0.0.0.0/0"]
	}
	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["${aws_instance.Bastion-Host.private_ip}/32"]
	}
	tags {
		Name = "Web-Server-sg"
	}
}

# EC2 Instance
resource "aws_instance" "Bastion-Host" {
	# AMI and Region
	ami = "ami-0bd1dc65d74266ee2"
	instance_type = "t2.micro"

	# Subnet ID
	subnet_id = "${aws_subnet.public_subnet_1a.id}"

	# Security Group
	vpc_security_group_ids = ["${aws_security_group.Bastion-Host-sg.id}"]

	# ssh key
	key_name = "testkey"

	tags {
		Name = "Bastion-Host"
	}
}


# EC2 Instance
resource "aws_instance" "Web-Server" {
	# AMI and Region
	ami = "ami-5b673c34"
	instance_type = "t2.micro"

	# Subnet ID
	subnet_id = "${aws_subnet.private_subnet_1a.id}"

	# Security Group
	vpc_security_group_ids = ["${aws_security_group.Web-Server-sg.id}"]

	# ssh key
	key_name = "testkey"

	tags {
		Name = "Web-Server"
	}
}

resource "aws_eip" "bastion_eip" {
	instance = "${aws_instance.Bastion-Host.id}"
	vpc = true
}