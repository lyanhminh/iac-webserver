resource "aws_instance" "jenkins_server" {
  ami           = var.ami_id 
  instance_type = var.instance_type
  subnet_id     = aws_subnet.project_subnet.id
  associate_public_ip_address = true
  tags = {
    Name    = "{var.project_name}-ec2"
    Project = var.project_name
  }

  vpc_security_group_ids = [aws_security_group.ubuntu_project_sg.id]
  key_name               = var.key_pair_name
}

output "public_ip" {
  value = aws_instance.jenkins_server.public_ip
}
