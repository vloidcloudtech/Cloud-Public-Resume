# ============================================================================
# Route 53 DNS Records
# ============================================================================
# Creates DNS records pointing to the CloudFront distribution

# ----------------------------------------------------------------------------
# A Record for Root Domain (vloidcloudtech.com)
# ----------------------------------------------------------------------------
resource "aws_route53_record" "frontend" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  # Alias record pointing to CloudFront distribution
  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}

# ----------------------------------------------------------------------------
# A Record for WWW Subdomain (www.vloidcloudtech.com)
# ----------------------------------------------------------------------------
resource "aws_route53_record" "frontend_www" {
  zone_id = var.route53_zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  # Alias record pointing to CloudFront distribution
  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}
