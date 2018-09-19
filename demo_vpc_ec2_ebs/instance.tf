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
}
