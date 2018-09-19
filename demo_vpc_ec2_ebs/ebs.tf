resource "aws_ebs_volume" "test-ebs" {
	availability_zone = "${aws_subnet.main-public-1a.availability_zone}"
	size = 10
	type = "gp2"
	tags {
		Name = "test-mount"
	}
}
resource "aws_volume_attachment" "ebs-attachment" {
  device_name = "/dev/xvdh"
  volume_id = "${aws_ebs_volume.test-ebs.id}"
  instance_id = "${aws_instance.test.id}"
}
