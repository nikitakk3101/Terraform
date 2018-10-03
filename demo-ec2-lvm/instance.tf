provider "aws" {
	region = "${var.AWS_REGION}"
}

variable "AWS_REGION" {
	default = "ap-south-1"
}
variable "AMIS" {
  type = "map"
  default = {
    ap-south-1 = "ami-76d6f519"
    us-west-2 = "ami-06b94666"
    eu-west-1 = "ami-844e0bf7"
  }
}

# VPC
resource "aws_vpc" "main-vpc" {
	cidr_block = "192.168.0.0/16"
	instance_tenancy =  "default"
	enable_dns_support = "true"
	enable_dns_hostnames = "true"
	enable_classiclink = "false"
	tags {
		Name = "main-vpc"
	}
}

# Subnets
resource "aws_subnet" "main-public-1a" {
	vpc_id = "${aws_vpc.main-vpc.id}"
	cidr_block =  "192.168.0.0/24"
	map_public_ip_on_launch = "true"
	availability_zone = "${var.AWS_REGION}a"
	tags {
		Name = "main-public-1a"
	}
}

resource "aws_subnet" "main-public-1b" {
	vpc_id = "${aws_vpc.main-vpc.id}"
	cidr_block =  "192.168.1.0/24"
	map_public_ip_on_launch = "true"
	availability_zone = "${var.AWS_REGION}b"
	tags {
		Name = "main-public-1b"
	}
}

# IGW
resource "aws_internet_gateway" "main-igw" {
	vpc_id = "${aws_vpc.main-vpc.id}"
	tags {
		Name = "main-igw"
	}
}

# Route tables
resource "aws_route_table" "public-route" {
	vpc_id = "${aws_vpc.main-vpc.id}"
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.main-igw.id}"
	}
	tags {
		Name = "public-route"
	}
}

# route association public
resource "aws_route_table_association" "main-public-1a" {
	subnet_id = "${aws_subnet.main-public-1a.id}"
	route_table_id = "${aws_route_table.public-route.id}"
}

resource "aws_route_table_association" "main-public-1b" {
	subnet_id = "${aws_subnet.main-public-1b.id}"
	route_table_id = "${aws_route_table.public-route.id}"
}

# Security Group

resource "aws_security_group" "allow-ssh" {
	vpc_id = "${aws_vpc.main-vpc.id}"
	name = "allow-ssh"
	description = "test-sg"
	# Outbound port
	egress {
		from_port = 0
		to_port = 0
		protocol = -1
		cidr_blocks = ["0.0.0.0/0"]
	}
	
	# Inbound Port
	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	tags {
		Name = "test-sg"
	}
}

# EC2 Instance
resource "aws_instance" "test" {

	# AMI and Region
	ami = "${lookup(var.AMIS, var.AWS_REGION)}"
	instance_type = "t2.micro"

	# Subnet ID
	subnet_id = "${aws_subnet.main-public-1a.id}"

	# Security Group
	vpc_security_group_ids = ["${aws_security_group.allow-ssh.id}"]

	# ssh key
	key_name = "testkey"

	tags {
		Name = "test"
	}
	
	# EBS Storage
	root_block_device {
		volume_type = "gp2"
		volume_size = 10
		delete_on_termination = "true"
	}
	ebs_block_device {
		device_name = "/dev/sdb"
		volume_type = "gp2"
		volume_size = 5
		delete_on_termination = "true"
	}
	ebs_block_device {
		device_name = "/dev/sdc"
		volume_type = "gp2"
		volume_size = 5
		delete_on_termination = "true"
	}
	# Run ebs_mount.sh file
  	user_data = "${file("mount.sh")}"

}
