locals {
  ami = "ami-005c06c6de69aee84"
}

resource "aws_instance" "first-ec2" {
  ami           = local.ami
  instance_type = var.instance_type
  tags = var.tags
}

resource "aws_eip" "first-ec2-eip" {
  vpc      = true
  instance = aws_instance.first-ec2.id
}