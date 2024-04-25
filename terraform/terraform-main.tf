provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "fn-s3-bucket" {
  bucket = "fn-s3-bucket" //creates an S3 bucket with the name fn-s3-bucket
  tags = {
    Name = "FnS3Bucket" // assigns a tag with key Name and value FnS3Bucket
  }
}

resource "aws_s3_bucket_acl" "fn-s3-bucket-acl" { //  configures the access control list (ACL) for the created S3 bucket
  bucket = aws_s3_bucket.fn-s3-bucket.id
  acl    = "private" // sets the ACL to private
}

resource "aws_s3_bucket_versioning" "fn-s3-bucket-vc" {  // configures the version control for the created S3 bucket
  bucket = aws_s3_bucket.fn-s3-bucket.id

  versioning_configuration {
    status = "Enabled" // enables versioning for the S3 bucket
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "fn-s3-bucket-lc" { // configures the bucket object lifecycle for the created S3 bucket
  bucket = aws_s3_bucket.fn-s3-bucket.id

  rule {
    id = "expire" // name of the versioning rule

    expiration {
      days = 365 // expires objects after 1 year
    }
    status = "Enabled"
  }
}

resource "aws_cloudfront_distribution" "example_distribution" {
  origin {
    domain_name = aws_s3_bucket.fn-s3-bucket.bucket_regional_domain_name //  sets up CloudFront to distribute content from the S3 bucket created earlier
    origin_id   = "fn-s3-bucket"

    s3_origin_config {
      origin_access_identity = "" // CloudFront accesses the S3 bucket using the default permissions
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "fn-s3-bucket"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https" // redirecting to https
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
