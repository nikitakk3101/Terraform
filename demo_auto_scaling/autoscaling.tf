# Variables
variable "AWS_REGION" {
  default = "ap-south-1"
}
variable "AMIS" {
  type = "map"
  default = {
    ap-south-1 = "ami-5b673c34"
  }
}
# Provider
provider "aws" { 
    region = "${var.AWS_REGION}"
}

# Internet VPC
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"
    enable_classiclink = "false"
    tags {
        Name = "main"
    }
}
# Subnets
resource "aws_subnet" "main-public-1a" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "${var.AWS_REGION}a"
    tags {
        Name = "main-public-1a"
    }
}
resource "aws_subnet" "main-public-1b" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "${var.AWS_REGION}b"
	tags {
        Name = "main-public-1a"
    }
}
resource "aws_subnet" "main-private-1a" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "10.0.4.0/24"
    map_public_ip_on_launch = "false"
    availability_zone = "${var.AWS_REGION}a"

    tags {
        Name = "main-private-1a"
    }
}
resource "aws_subnet" "main-private-1b" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "10.0.5.0/24"
    map_public_ip_on_launch = "false"
    availability_zone = "${var.AWS_REGION}b"

    tags {
        Name = "main-private-1b"
    }
}
# Internet GW
resource "aws_internet_gateway" "main-gw" {
    vpc_id = "${aws_vpc.main.id}"

    tags {
        Name = "main"
    }
}

# route tables
resource "aws_route_table" "main-public" {
    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.main-gw.id}"
    }

    tags {
        Name = "public-route"
    }
}

# route associations public
resource "aws_route_table_association" "main-public-1a" {
    subnet_id = "${aws_subnet.main-public-1a.id}"
    route_table_id = "${aws_route_table.main-public.id}"
}
resource "aws_route_table_association" "main-public-1b" {
    subnet_id = "${aws_subnet.main-public-1b.id}"
    route_table_id = "${aws_route_table.main-public.id}"
}

# Autoscaling SG
resource "aws_security_group" "instance-sg" {
  vpc_id = "${aws_vpc.main.id}"
  name = "allow-ssh"
  description = "security group that allows ssh and all egress traffic"
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  } 
tags {
    Name = "instance-sg"
  }
}

# Autoscaling Launch Configuration

resource "aws_launch_configuration" "test-launchconfig" {
  name_prefix          = "test-launchconfig"
  image_id             = "${lookup(var.AMIS, var.AWS_REGION)}"
  instance_type        = "t2.micro"
  key_name             = "testkey"
  security_groups      = ["${aws_security_group.instance-sg.id}"]
  user_data = "${file("script.sh")}"
}

# Autoscaling Group
resource "aws_autoscaling_group" "test-autoscaling" {
  name                 = "test-autoscaling"
  vpc_zone_identifier  = ["${aws_subnet.main-public-1a.id}", "${aws_subnet.main-public-1b.id}"]
  launch_configuration = "${aws_launch_configuration.test-launchconfig.name}"
  min_size             = 1
  max_size             = 2
  health_check_grace_period = 300
  health_check_type = "EC2"
  force_delete = true

  tag {
      key = "Name"
      value = "ec2 instance"
      propagate_at_launch = true
  }
}

# Autoscaling policy
# scale up alarm
resource "aws_autoscaling_policy" "scaleup-policy" {
  name                   = "scaleup-policy"
  autoscaling_group_name = "${aws_autoscaling_group.test-autoscaling.name}"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}
#Cloud watch alarm
resource "aws_cloudwatch_metric_alarm" "cpu-alarm-scaleup" {
  alarm_name          = "cpu-alarm-scaleup"
  alarm_description   = "cpu-alarm-scaleup"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"
  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.test-autoscaling.name}"
  }
  actions_enabled = true
  alarm_actions   = ["${aws_autoscaling_policy.scaleup-policy.arn}"]
}

# scale down alarm
resource "aws_autoscaling_policy" "scaledown-policy" {
  name                   = "scaledown-policy"
  autoscaling_group_name = "${aws_autoscaling_group.test-autoscaling.name}"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "cpu-alarm-scaledown" {
  alarm_name          = "cpu-alarm-scaledown"
  alarm_description   = "cpu-alarm-scaledown"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "5"

  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.test-autoscaling.name}"
  }

  actions_enabled = true
  alarm_actions   = ["${aws_autoscaling_policy.scaledown-policy.arn}"]
}
