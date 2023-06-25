variable "ami" {}

variable "ec2_instance_type" {}

variable "ssh_key_name" {}

variable "iam_instance_profile" {}
variable "availability_zone" {}
variable "subnet_id" {}

variable "vpc_security_group_ids_list" { type = list(strings) }

variable "tags" { type = map(strings) }


resource "aws_instance" "main" {
  ami           = var.ami
  instance_type = var.ec2_instance_type
  key_name      = var.ssh_key_name
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
    delete_on_termination = true
  }

  iam_instance_profile = var.iam_instance_profile

  availability_zone = var.availability_zone

  subnet_id = var.subnet_id

  vpc_security_group_ids = var.vpc_security_group_ids_list

  tags = var.tags
}