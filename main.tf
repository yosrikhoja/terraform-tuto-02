terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.2.0"
}

# Fetch default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetch a single subnet by CIDR block (adjust this to your target subnet)
data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  
}

# Security group for EC2
resource "aws_security_group" "allow_http" {
  name        = "web"
  description = "Allow HTTP traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for ALB
resource "aws_security_group" "alb" {
  name        = "alb"
  description = "Allow HTTP traffic to ALB"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch Configuration for Auto Scaling Group
resource "aws_launch_template" "example" {
  name_prefix   = "example-"
  image_id      = "ami-0f88e80871fd81e91"
  instance_type = "t3.micro"

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "Hello, World!" > index.html
              nohup python3 -m http.server 80 &
            EOF
  )

  vpc_security_group_ids = [aws_security_group.allow_http.id]
}

# Application Load Balancer
resource "aws_lb" "example" {
  name               = "example-lb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.selected.ids # ✅ List format required
  security_groups    = [aws_security_group.alb.id]
}

# Target group for ALB
resource "aws_lb_target_group" "example" {
  name     = "example-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Listener for ALB
resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found!"
      status_code  = "404"
    }
  }
}

# Listener rule to forward traffic
resource "aws_lb_listener_rule" "asg" {
  listener_arn    = aws_lb_listener.example.arn
  priority        = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "example" {
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }

  vpc_zone_identifier  = data.aws_subnets.selected.ids
  target_group_arns    = [aws_lb_target_group.example.arn]
  health_check_type    = "ELB"
  min_size             = 1
  max_size             = 2

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}
