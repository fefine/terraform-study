output "ip" {
  value = aws_eip.first-ec2-eip.public_ip
}

output "id" {
  value = aws_instance.first-ec2.id
}