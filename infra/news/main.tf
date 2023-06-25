data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.prefix}/base/vpc_id"
}
data "aws_ssm_parameter" "subnet" {
  name = "/${var.prefix}/base/subnet/a/id"
}

# Refactoring
data "aws_ssm_parameter" "subnet_zone_b" {
  name = "/${var.prefix}/base/subnet/b/id"
}

data "aws_ssm_parameter" "ecr" {
  name = "/${var.prefix}/base/ecr"
}

locals {
  vpc_id    = data.aws_ssm_parameter.vpc_id.value
  subnet_id = data.aws_ssm_parameter.subnet.value

  # Refactoring
  subnet_zone_b_id = data.aws_ssm_parameter.subnet_zone_b.value

  ecr_url = data.aws_ssm_parameter.ecr.value
}

# TODO: only allow current IP address 
resource "aws_security_group" "ssh_access" {
  vpc_id      = "${local.vpc_id}"
  name        = "${var.prefix}-ssh_access"
  description = "SSH access group"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "Allow HTTP"
    createdBy = "infra-${var.prefix}/news"
  }
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "${var.prefix}-news"
  public_key = "${file("${path.module}/../id_rsa.pub")}"
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["137112412989"] #amazon
}

### Front end

resource "aws_instance" "front_end" {
  ami                         = "${data.aws_ami.amazon_linux_2.id}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${aws_key_pair.ssh_key.key_name}"
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 8
    delete_on_termination = true
  }

  iam_instance_profile = "${var.prefix}-news_host"

  availability_zone = "${var.region}a"

  subnet_id = local.subnet_id

  vpc_security_group_ids = [
    "${aws_security_group.front_end_sg.id}",
    "${aws_security_group.ssh_access.id}"
  ]

  tags = {
    Name      = "${var.prefix}-front_end"
    createdBy = "infra-${var.prefix}/news"
  }

  connection {
    host        = "${self.public_ip}"
    type        = "ssh"
    user        = "ec2-user"
    private_key = "${file("${path.module}/../id_rsa")}"
  }

  provisioner "remote-exec" {
    script = "${path.module}/provision-docker.sh"
  }
}

module "froent_end_zone_b" {
  source = "./module/ec2"

}

### end of front-end

resource "aws_instance" "quotes" {
  ami                         = "${data.aws_ami.amazon_linux_2.id}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${aws_key_pair.ssh_key.key_name}"
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 8
    delete_on_termination = true
  }

  iam_instance_profile = "${var.prefix}-news_host"

  availability_zone = "${var.region}a"

  subnet_id = local.subnet_id

  vpc_security_group_ids = [
    "${aws_security_group.quotes_sg.id}",
    "${aws_security_group.ssh_access.id}"
  ]

  tags = {
    Name      = "${var.prefix}-quotes"
    createdBy = "infra-${var.prefix}/news"
  }

  connection {
    host        = "${self.public_ip}"
    type        = "ssh"
    user        = "ec2-user"
    private_key = "${file("${path.module}/../id_rsa")}"
  }

  provisioner "remote-exec" {
    script = "${path.module}/provision-docker.sh"
  }
}

resource "null_resource" "quotes_provision" {
  connection {
    host        = "${aws_instance.quotes.public_ip}"
    type        = "ssh"
    user        = "ec2-user"
    private_key = "${file("${path.module}/../id_rsa")}"
  }
  provisioner "file" {
    source      = "${path.module}/provision-quotes.sh"
    destination = "/home/ec2-user/provision.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/provision.sh",
      "/home/ec2-user/provision.sh ${local.ecr_url}quotes:latest"
    ]
  }
}

resource "aws_instance" "newsfeed" {
  ami                         = "${data.aws_ami.amazon_linux_2.id}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${aws_key_pair.ssh_key.key_name}"
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 8
    delete_on_termination = true
  }

  iam_instance_profile = "${var.prefix}-news_host"

  availability_zone = "${var.region}a"

  subnet_id = local.subnet_id

  vpc_security_group_ids = [
    "${aws_security_group.newsfeed_sg.id}",
    "${aws_security_group.ssh_access.id}"
  ]

  tags = {
    Name      = "${var.prefix}-newsfeed"
    createdBy = "infra-${var.prefix}/news"
  }

  connection {
    host        = "${self.public_ip}"
    type        = "ssh"
    user        = "ec2-user"
    private_key = "${file("${path.module}/../id_rsa")}"
  }

  provisioner "remote-exec" {
    script = "${path.module}/provision-docker.sh"
  }
}

resource "null_resource" "newsfeed_provision" {
  connection {
    host        = "${aws_instance.newsfeed.public_ip}"
    type        = "ssh"
    user        = "ec2-user"
    private_key = "${file("${path.module}/../id_rsa")}"
  }
  provisioner "file" {
    source      = "${path.module}/provision-newsfeed.sh"
    destination = "/home/ec2-user/provision.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/provision.sh",
      "/home/ec2-user/provision.sh ${local.ecr_url}newsfeed:latest"
    ]
  }
}

resource "null_resource" "front_end_provision" {
  connection {
    host        = "${aws_instance.front_end.public_ip}"
    type        = "ssh"
    user        = "ec2-user"
    private_key = "${file("${path.module}/../id_rsa")}"
  }
  provisioner "file" {
    source      = "${path.module}/provision-front_end.sh"
    destination = "/home/ec2-user/provision.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/provision.sh",
      <<EOF
      /home/ec2-user/provision.sh \
      --region ${var.region} \
      --docker-image ${local.ecr_url}front_end:latest \
      --quote-service-url http://${aws_instance.quotes.private_ip}:8082 \
      --newsfeed-service-url http://${aws_instance.newsfeed.private_ip}:8081 \
      --static-url http://${aws_s3_bucket.news.website_endpoint}
    EOF
    ]
  }
}

### ALB Start 

resource "aws_security_group" "alb_sg" {
  vpc_id      = "${local.vpc_id}"
  name        = "${var.prefix}-alb_http_access"
  description = "HTTP access"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    protocol    = "-1"
    to_port     = "0"
  }

  tags = {
    Name      = "Allow HTTP"
    createdBy = "infra-${var.prefix}/global"
  }
}

resource "aws_lb" "alb_frontend" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.alb_sg.id}"]
  subnets            = ["${local.subnet_id}", "${local.subnet_zone_b_id}"]

  enable_deletion_protection = true


  tags = {
    Name      = "${var.prefix}-alb"
    createdBy = "infra-${var.prefix}/global"
  }

}

resource "aws_lb_target_group" "alb_frontend" {
  name     = "frontend-news"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "${local.vpc_id}"
  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 10
    matcher             = 200
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 3
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "alb_frontend" {
  target_group_arn = aws_lb_target_group.alb_frontend.arn
  target_id        = aws_instance.front_end.id
  port             = 8080
}

resource "aws_lb_listener" "alb_frontend" {
  load_balancer_arn = aws_lb.alb_frontend.arn
  port              = "80"
  protocol          = "HTTP"



  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_frontend.arn

  }


}

### ALB End

### Outputs Start

output "frontend_url" {
  value = "http://${aws_instance.front_end.public_ip}:8080"
}

output "alb_dns_name" {
  value = "http://${aws_lb.alb_frontend.dns_name}/"
}

### Outputs End