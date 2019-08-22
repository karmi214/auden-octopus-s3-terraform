provider "aws" {
}
terraform {
  backend "s3" {
    bucket = "auden-octopus-terraform-releasetour"
    key    = "s3.tfstate"
    region = "us-east-1"
  }
}
resource "aws_s3_bucket" "auden-bucket" {
  bucket = "${var.bucket_name}"
  acl    = "public"
  tags = {
    Name        = "Auden Bucket"
  }
}