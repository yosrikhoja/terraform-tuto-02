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
  tags = {
    Name = "server"
  }
}