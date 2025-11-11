# ============================================================================
# AWS Certificate Manager (ACM) Certificate
# ============================================================================
# Creates an SSL/TLS certificate for the custom domain
# Certificate must be in us-east-1 region for CloudFront

# NOTE: ACM certificate must be created in us-east-1 for CloudFront
resource "aws_acm_certificate" "frontend" {
  # CloudFront requires certificates to be in us-east-1
  provider = aws.us_east_1

  domain_name       = var.domain_name
  validation_method = "DNS"

  # Add www subdomain as Subject Alternative Name
  subject_alternative_names = ["www.${var.domain_name}"]

  # Replace certificate instead of destroying and recreating
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name = "Portfolio Frontend Certificate"
    }
  )
}

# ============================================================================
# Certificate Validation
# ============================================================================
# Automatically validate the certificate using DNS records in Route 53

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.frontend.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

# Wait for certificate validation to complete
resource "aws_acm_certificate_validation" "frontend" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.frontend.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "10m" # Wait up to 10 minutes for validation
  }
}
