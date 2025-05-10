terraform {
  backend "s3" {
    bucket = "terraform-tuto-02"
    key    = "terraform-tuto-02.tfstate"
    region = "us-east-1"
  }
}