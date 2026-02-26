locals {
  bucket_name = lower(replace("${var.project_name}-${var.env_name}-signin-${random_id.suffix.hex}", "_", "-"))
  files       = fileset(var.site_dir, "**")
  index_key   = "index.html"

  rendered_index = replace(
    file("${var.site_dir}/${local.index_key}"),
    "__API_BASE_URL__",
    var.api_base_url
  )

  site_files = {
    for file in local.files : file => file
    if !endswith(file, "/") && file != local.index_key
  }

  site_file_hashes = [
    for file in sort(keys(local.site_files)) : filemd5("${var.site_dir}/${file}")
  ]

  site_hash = md5(join("", concat([md5(local.rendered_index)], local.site_file_hashes)))

  mime_types = {
    ".html" = "text/html"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".json" = "application/json"
    ".svg"  = "image/svg+xml"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".ico"  = "image/x-icon"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "site" {
  bucket = local.bucket_name
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${var.project_name}-${var.env_name}-signin-oac"
  description                       = "OAC for ${var.project_name} ${var.env_name} sign-in site"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  wait_for_deployment = false
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "signinSiteS3"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "signinSiteS3"

    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
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

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudFrontRead"
      Effect = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.site.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.site.arn
        }
      }
    }]
  })
}

resource "aws_s3_object" "site_files" {
  for_each = local.site_files

  bucket       = aws_s3_bucket.site.id
  key          = each.value
  source       = "${var.site_dir}/${each.value}"
  etag         = filemd5("${var.site_dir}/${each.value}")
  content_type = lookup(local.mime_types, regex("\\.[^.]+$", each.value), "application/octet-stream")
}

resource "aws_s3_object" "site_index" {
  bucket       = aws_s3_bucket.site.id
  key          = local.index_key
  content      = local.rendered_index
  etag         = md5(local.rendered_index)
  content_type = lookup(local.mime_types, ".html", "text/html")
}

resource "aws_cloudfront_invalidation" "site" {
  distribution_id = aws_cloudfront_distribution.site.id
  paths           = ["/*"]

  triggers = {
    site_hash = local.site_hash
  }

  depends_on = [
    aws_s3_object.site_index,
    aws_s3_object.site_files,
  ]
}
