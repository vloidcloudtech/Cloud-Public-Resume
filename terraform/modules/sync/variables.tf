variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "github_username" {
  description = "GitHub username"
  type        = string
}

variable "medium_username" {
  description = "Medium username"
  type        = string
}

variable "youtube_channel_id" {
  description = "YouTube channel ID"
  type        = string
}

variable "github_token_secret_arn" {
  description = "ARN of GitHub token in Secrets Manager"
  type        = string
}

variable "youtube_api_key_secret_arn" {
  description = "ARN of YouTube API key in Secrets Manager"
  type        = string
}

variable "ai_api_key_secret_arn" {
  description = "ARN of AI API key in Secrets Manager"
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
