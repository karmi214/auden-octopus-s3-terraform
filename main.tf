provider "aws" {
}
terraform {
  backend "s3" {
    bucket = "auden-octopus-terraform-releasetour"
    key    = "s3.cloudfront.tfstate"
    region = "us-east-1"
  }
}
resource "aws_s3_bucket" "auden_bucket" {
  bucket = "auden-octopus-frontend-bucket-${var.release}"
  acl    = "public-read"
  tags = {
    Name = "Auden Bucket"
  }
  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}
resource "aws_s3_bucket_policy" "b" {
  bucket = "${aws_s3_bucket.auden_bucket.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "MYBUCKETPOLICY",
  "Statement": [
    {
      "Sid": "IPAllow",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": "${aws_s3_bucket.auden_bucket.arn}/*"
    }
  ]
}
POLICY
}
locals {
  s3_origin_id = "myS3Origin"
}
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Origin access identity for ${aws_s3_bucket.auden_bucket.id}"
}
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.auden_bucket.bucket_regional_domain_name}"
    origin_id   = "${local.s3_origin_id}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path}"
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${aws_s3_bucket.auden_bucket.id}"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.s3_origin_id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }


  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "Test"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
output "cloufrontid" {
  value = "${aws_cloudfront_distribution.s3_distribution.id}"
}
output "bucketname" {
  value = "${aws_s3_bucket.auden_bucket.id}"
}
