variable "project_name" {
}

variable "instance_type" {
}

variable "key_pair_name" {
}

variable "ami_id" {

}

variable "owner" {
}


data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "image-id"
    values = [var.ami_id]
  }
  owners = [var.owner]
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.project_subnet.id
  tags = {
    Name    = "MinhsProject1-ec2"
    Project = var.project_name
  }

  vpc_security_group_ids = [aws_security_group.ubuntu_project_sg.id]
  key_name               = var.key_pair_name
}
