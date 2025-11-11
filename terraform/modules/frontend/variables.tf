# ============================================================================
# Frontend Module Variables
# ============================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (production, staging, development)"
  type        = string
}

variable "domain_name" {
  description = "Custom domain name for the website (e.g., vloidcloudtech.com)"
  type        = string
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID for the domain"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
