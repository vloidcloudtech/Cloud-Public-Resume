# ============================================================================
# Frontend Module Outputs
# ============================================================================

output "bucket_name" {
  description = "Frontend S3 bucket name"
  value       = aws_s3_bucket.frontend.id
}

output "bucket_arn" {
  description = "Frontend S3 bucket ARN"
  value       = aws_s3_bucket.frontend.arn
}

output "cloudfront_url" {
  description = "CloudFront distribution URL"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.frontend.id
}

output "website_url" {
  description = "Custom domain website URL"
  value       = "https://${var.domain_name}"
}

output "website_url_www" {
  description = "Custom domain website URL with www"
  value       = "https://www.${var.domain_name}"
}

output "certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.frontend.arn
}
