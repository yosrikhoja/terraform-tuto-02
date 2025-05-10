terraform {
  backend "s3" {
    bucket = "terraform-tuto-002"
    key    = "terraform-tuto-02.tfstate"
    region = "us-east-1"
  }
}