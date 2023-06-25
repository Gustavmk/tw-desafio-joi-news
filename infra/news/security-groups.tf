# Allow only current IP address 
data "http" "current_public_ip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group" "ssh_access" {
  vpc_id      = "${local.vpc_id}"
  name        = "${var.prefix}-ssh_access"
  description = "SSH access group"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.current_public_ip.body)}/32"]

  }

  tags = {
    // refactoring
    Name      = "Allow Current Public IP trought SSH"
    createdBy = "infra-${var.prefix}/news"
  }
}


### Frontend Start
resource "aws_security_group" "front_end_sg" {
  vpc_id      = "${local.vpc_id}"
  name        = "${var.prefix}-front_end"
  description = "Security group for front_end"

  tags = {
    Name      = "SG for front_end"
    createdBy = "infra-${var.prefix}/news"
  }
}

# Allow public access to the front-end server
resource "aws_security_group_rule" "front_end" {
  type        = "ingress"
  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.front_end_sg.id}"
}

# Allow all outbound connections
resource "aws_security_group_rule" "front_end_all_out" {
  type              = "egress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.front_end_sg.id}"
}

### Frontend End

### Quotes Start
resource "aws_security_group" "quotes_sg" {
  vpc_id      = "${local.vpc_id}"
  name        = "${var.prefix}-quotes_sg"
  description = "Security group for quotes"

  tags = {
    Name      = "SG for quotes"
    createdBy = "infra-${var.prefix}/news"
  }
}

# Allow all outbound connections
resource "aws_security_group_rule" "quotes_all_out" {
  type              = "egress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.quotes_sg.id}"
}

# Allow internal access to the quotes HTTP server from front-end
resource "aws_security_group_rule" "quotes_internal_http" {
  type                     = "ingress"
  from_port                = 8082
  to_port                  = 8082
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.front_end_sg.id}"
  security_group_id        = "${aws_security_group.quotes_sg.id}"
}

### Quotes End

### Newsfeed Start

resource "aws_security_group" "newsfeed_sg" {
  vpc_id      = "${local.vpc_id}"
  name        = "${var.prefix}-newsfeed_sg"
  description = "Security group for newsfeed"

  tags = {
    Name      = "SG for newsfeed"
    createdBy = "infra-${var.prefix}/news"
  }
}

# Allow all outbound connections
resource "aws_security_group_rule" "newsfeed_all_out" {
  type              = "egress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.newsfeed_sg.id}"
}

# Allow internal access to the newsfeed HTTP server from front-end
resource "aws_security_group_rule" "newsfeed_internal_http" {
  type                     = "ingress"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.front_end_sg.id}"
  security_group_id        = "${aws_security_group.newsfeed_sg.id}"
}


### Newsfeed End

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


### ALB End