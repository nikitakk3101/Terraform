variable AWS_ACCESS_KEY {}
variable AWS_SECRET_KEY {}
variable AWS_REGION {
	default = "ap-south-1"
}
variable AMI {
	type = "map" 
	default = {
		us-east-1 = "ami-72c4e81d"	
		ap-south-1 = "ami-76d6f519"
		ap-sotheast-1 = "ami-72c4e81d"
	}
}
variable PATH_TO_PUBLIC_KEY {
	default = "mykey.pub"
}
variable PATH_TO_PRIAVTE_KEY {
	default = "mykey.ppk"
}

variable INSTANCE_USER_NAME {
	default = "ec2-user"
}