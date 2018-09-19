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
  }
}
variable "RDS_PASSWORD" {}

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

# PublicSubnet-1a
resource "aws_subnet" "main-public-1a" {
	vpc_id = "${aws_vpc.main-vpc.id}"
	cidr_block =  "192.168.0.0/24"
	map_public_ip_on_launch = "true"
	availability_zone = "${var.AWS_REGION}a"
	tags {
		Name = "main-public-1a"
	}
}

# PrivateSubnet-1a
resource "aws_subnet" "main-private-1a" {
	vpc_id = "${aws_vpc.main-vpc.id}"
	cidr_block =  "192.168.1.0/24"
	map_public_ip_on_launch = "false"
	availability_zone = "${var.AWS_REGION}a"
	tags {
		Name = "main-private-1a"
	}
}

# PrivateSubnet-1b
resource "aws_subnet" "main-private-1b" {
	vpc_id = "${aws_vpc.main-vpc.id}"
	cidr_block =  "192.168.2.0/24"
	map_public_ip_on_launch = "false"
	availability_zone = "${var.AWS_REGION}b"
	tags {
		Name = "main-private-1b"
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

# EC2 Security Group

resource "aws_security_group" "instance-sg" {
	vpc_id = "${aws_vpc.main-vpc.id}"
	name = "instance-sg"
	description = "instance-sg"
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
		Name = "instance-sg"
	}
}

# RDS Security Group

resource "aws_security_group" "rds-sg" {
	vpc_id = "${aws_vpc.main-vpc.id}"
	name = "rds-sg"
	description = "rds-sg"
	egress {
		from_port = 0
		to_port = 0
		protocol = -1
		cidr_blocks = ["0.0.0.0/0"]
	}
	ingress {
		from_port = 3306
		to_port = 3306
		protocol = "tcp"
		security_groups = ["${aws_security_group.instance-sg.id}"]
	}
	tags {
		Name = "rds-sg"
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
	vpc_security_group_ids = ["${aws_security_group.instance-sg.id}"]

	# ssh key
	key_name = "testkey"
	
	tags {
		Name = "test"
	}
	
	user_data = "${file("script.sh")}"
}

# RDS Subnet Group

resource "aws_db_subnet_group" "rds-sng" {
	name = "rds-sng"
	description = "RDS Subnet Group"
	subnet_ids = ["${aws_subnet.main-private-1a.id}","${aws_subnet.main-private-1b.id}"]
}

# Parameter Group

resource "aws_db_parameter_group" "mysql-parameters" {
    name = "mysql-parameters"
    family = "mysql5.6"
    description = "MySQL parameter group"

    parameter {
      name = "max_allowed_packet"
      value = "16777216"
   }
}

resource "aws_db_instance" "mydb-test" {
  allocated_storage    = 30
  engine               = "mysql"
  engine_version       = "5.6.39"
  instance_class       = "db.t2.micro"
  identifier           = "mydb"
  name                 = "mydb"
  username             = "root"
  password             = "${var.RDS_PASSWORD}"
  db_subnet_group_name = "${aws_db_subnet_group.rds-sng.name}"
  parameter_group_name = "${aws_db_parameter_group.mysql-parameters.name}"
  multi_az             = "false"     # set to true to have high availability: 2 instances synchronized with each other
  vpc_security_group_ids = ["${aws_security_group.rds-sg.id}"]
  storage_type         = "gp2"
  backup_retention_period = 7   # how long you’re going to keep your backups
  availability_zone = "${aws_subnet.main-private-1a.availability_zone}"   # prefered AZ
  skip_final_snapshot = true   # skip final snapshot when doing terraform destroy
  tags {
      Name = "mysql-instance"
  }
}

