# ============================================================================
# Secrets Module Variables
# ============================================================================

variable "project_name" {
  description = "Project name for secret naming"
  type        = string
}

variable "environment" {
  description = "Environment name (production, staging, development)"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to secrets"
  type        = map(string)
  default     = {}
}
