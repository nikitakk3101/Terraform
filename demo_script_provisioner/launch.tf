# Defines Provider

provider "aws" {
	region = "${var.AWS_REGION}"
}

# defines variable

variable "AWS_REGION" {
	default = "ap-south-1"
}
variable "AMIS" {
	type = "map"
	default = {
    ap-south-1 = "ami-5b673c34"
    us-west-2 = "ami-06b94666"
    eu-west-1 = "ami-844e0bf7"
  }
}
variable "INSTANCE_USERNAME" {
	default = "ec2-user"
}
variable "PATH_TO_PRIVATE_KEY" {
  default = "testkey.pem"
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

# Subnet-1a
resource "aws_subnet" "main-public-1a" {
	vpc_id = "${aws_vpc.main-vpc.id}"
	cidr_block =  "192.168.0.0/24"
	map_public_ip_on_launch = "true"
	availability_zone = "${var.AWS_REGION}a"
	tags {
		Name = "main-public-1a"
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

# Security Group

resource "aws_security_group" "allow-ssh" {
	vpc_id = "${aws_vpc.main-vpc.id}"
	name = "allow-ssh"
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
		cidr_blocks = ["0.0.0.0/0"]
	}
	ingress {
		from_port = 80
		to_port = 80
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
	
	#provisioner
	
	provisioner "file" {
		source = "script.sh"
		destination = "/tmp/script.sh"
	}
	
	provisioner "remote-exec" {
		inline = [
			"chmod +x /tmp/script.sh",
			"sudo /tmp/script.sh"
		]
	}

	connection {
		user = "${var.INSTANCE_USERNAME}"
		private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
	}
	tags {
		Name = "test"
	}
}
