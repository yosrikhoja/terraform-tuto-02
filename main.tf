terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.2.0"
}
resource "aws_instance" "example" {
  ami           = "ami-0f88e80871fd81e91" 
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.allow_http.id]
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World!" > index.html
              nohup python3 -m http.server 80 &
              EOF
    user_data_replace_on_change = true
    tags = {
    Name = "server"
  }
}
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