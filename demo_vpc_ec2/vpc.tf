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
# Subnet-1b
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