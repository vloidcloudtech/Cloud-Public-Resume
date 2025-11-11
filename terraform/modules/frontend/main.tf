# S3 Bucket for Frontend
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${var.environment}"

  tags = var.tags
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.frontend]
}

# ============================================================================
# CloudFront Distribution with Custom Domain
# ============================================================================
# Serves the React frontend from S3 with global CDN distribution
# Configured with custom domain (vloidcloudtech.com) and SSL certificate

resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100" # US, Canada, Europe (lowest cost)
  comment             = "Portfolio Aggregator - ${var.environment}"

  # Custom domain aliases
  aliases = [
    var.domain_name,         # vloidcloudtech.com
    "www.${var.domain_name}" # www.vloidcloudtech.com
  ]

  # ----------------------------------------------------------------------------
  # S3 Origin Configuration
  # ----------------------------------------------------------------------------
  origin {
    domain_name = aws_s3_bucket_website_configuration.frontend.website_endpoint
    origin_id   = "S3-${aws_s3_bucket.frontend.id}"

    # Use custom origin config (not S3 origin config) for website endpoint
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # S3 website endpoint only supports HTTP
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # ----------------------------------------------------------------------------
  # Default Cache Behavior
  # ----------------------------------------------------------------------------
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.frontend.id}"
    viewer_protocol_policy = "redirect-to-https" # Force HTTPS for security
    compress               = true                # Enable Gzip compression

    forwarded_values {
      query_string = false # Don't forward query strings to S3

      cookies {
        forward = "none" # Don't forward cookies
      }
    }

    # Cache TTL settings
    min_ttl     = 0     # Minimum time to cache (0 = respect Cache-Control)
    default_ttl = 3600  # Default cache time: 1 hour
    max_ttl     = 86400 # Maximum cache time: 24 hours
  }

  # ----------------------------------------------------------------------------
  # Geographic Restrictions
  # ----------------------------------------------------------------------------
  restrictions {
    geo_restriction {
      restriction_type = "none" # Allow access from all countries
    }
  }

  # ----------------------------------------------------------------------------
  # SSL/TLS Certificate Configuration
  # ----------------------------------------------------------------------------
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.frontend.certificate_arn
    ssl_support_method       = "sni-only"     # Use SNI (free, modern browsers only)
    minimum_protocol_version = "TLSv1.2_2021" # Require TLS 1.2 or higher
  }

  # ----------------------------------------------------------------------------
  # Custom Error Responses
  # ----------------------------------------------------------------------------
  # Handle React Router by redirecting 404s to index.html
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  # Wait for certificate validation before creating distribution
  depends_on = [aws_acm_certificate_validation.frontend]

  tags = var.tags
}
