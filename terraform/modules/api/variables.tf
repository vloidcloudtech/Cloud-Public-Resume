variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "github_repos_table_name" {
  description = "GitHub repos table name"
  type        = string
}

variable "github_repos_table_arn" {
  description = "GitHub repos table ARN"
  type        = string
}

variable "medium_posts_table_name" {
  description = "Medium posts table name"
  type        = string
}

variable "medium_posts_table_arn" {
  description = "Medium posts table ARN"
  type        = string
}

variable "youtube_videos_table_name" {
  description = "YouTube videos table name"
  type        = string
}

variable "youtube_videos_table_arn" {
  description = "YouTube videos table ARN"
  type        = string
}

variable "sync_metadata_table_name" {
  description = "Sync metadata table name"
  type        = string
}

variable "sync_metadata_table_arn" {
  description = "Sync metadata table ARN"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
