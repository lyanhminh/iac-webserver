variable "project_name" {
}

variable "instance_type" {
}

variable "key_pair_name" {
}

data "aws_ami" "ubuntu" {
  most_recent = true
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  tags = {
    Name    = "MinhsProject1"
    Project = var.project_name
  }

  keyname = var.key_pair_name
}
