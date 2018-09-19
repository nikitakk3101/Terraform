resource "aws_key_pair" "mykey" {
	key_name = "mykey"
	public_key = "${file("${var.PATH_TO_PUBLIC_KEY}")}"
}


resource "aws_instance" "demo1" {
	ami = "${lookup(var.AMI, var.AWS_REGION)}"
	instance_type = "t2.micro"
	key_name = "${aws_key_pair.mykey.key_name}"
	connection {
	user = "${var.INSTANCE_USER_NAME}"
	private_key = "${file(${var.PATH_TO_PRIVATE_KEY})}"
	}
}

