# Defines Variable
variable "AWS_REGION" {
	default = "ap-south-1"
}

variable "AMIS" {
	type = "map"
	default = "ami-5b673c34"
}

# Define Provider
provider  "aws" {
	region = "${var.AWS_REGION}"	
}

# VPC
resource "aws_vpc" "main-vpc" {
	cidr_block = "10.1.0.0/16"
	instance_tenancy = "default"
	enable_dns_support = "true"
	enable_dns_hostname = "false"
	tags {
		Name = "main-vpc"
	}
}

# PublicSubnet-1a
resource "aws_subnet" "main-public-1a" {
	vpc_id = "${aws_vpc.main-vpc.id}"
	cidr_block = "10.1.0.0/24"
	map_public_ip_on_launch = "true"
	availability_zone = "${var.AWS_REGION}a"
	tags {
		Name = "PublicSubnet-1a"
	}
}

#IGW
resource "aws_internet_gateway" "main-igw" {
	vpc_id = "${aws_vpc.main-vpc.id}"
	tags {
		Name = "main-igw"
	}
}

#Route-Table
resource "aws_route_table" "public-route" {
	vpc_id = "${aws_vpc.main-vpc.id}"
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.main-igw.id}"
	}
	tags {
		Name = "Public-route"
	}
}

# Route association public
resource "aws_route_table_association" "main-public" {
	subnet_id = "${aws_subnet.main-public-1a.id}"
	route_table_id = "${aws_route_table.public-route.id}"
}

# EC2 security group
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

# S3 bucket
resource "aws_s3_bucket" "my-bucket" {
	bucket = "niki-tf-test-bucket"
	acl =  "private"
	tags {
		Name = "My-bucket"
		ENV = "Test"
	}
}

# IAM role
resource "aws_iam_role" "my-bucket-role" {
	name = "AccessRole"
	assume_role_policy = << EOF 
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
}

resource "aws_iam_role_policy" "s3-mybucket-role-policy" {
    name = "s3-mybucket-role-policy"
    role = "${aws_iam_role.s3-mybucket-role.id}"
    policy = << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "s3:*"
            ],
            "Resource": [
              "arn:aws:s3:::niki-tf-test-bucket",
              "arn:aws:s3:::niki-tf-test-bucket/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "role-instanceprofile" {
    name = "s3-mybucket-role"
    role = "${aws_iam_role.s3-mybucket-role.name}"
}

# EC2 instance
resource "aws_instance" "test" {
	ami= "${lookup(var.AMIS, var.AWS_REGION)}"
	instance_type = "t2.micro"
	vpc_id = "${aws_vpc.main-vpc.id}"
  	subnet_id = "${aws_subnet.main-public-1.id}"
	vpc_security_group_ids = ["${aws_security_group.instance-sg.id}"]
	key_name = "testkey"
	iam_instance_profile = "${aws_iam_instance_profile.role-instanceprofile.name}"
	tags {
		Name = "test-instance"
	}
	user_data = "${file("script.sh")}"	
}
