# GitHub Repositories Table
resource "aws_dynamodb_table" "github_repos" {
  name         = "${var.project_name}-github-repos-${var.environment}"
  billing_mode = "PAY_PER_REQUEST" # On-demand pricing
  hash_key     = "repo_id"

  attribute {
    name = "repo_id"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = false
  }

  tags = var.tags
}

# Medium Posts Table
resource "aws_dynamodb_table" "medium_posts" {
  name         = "${var.project_name}-medium-posts-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "post_id"

  attribute {
    name = "post_id"
    type = "S"
  }

  tags = var.tags
}

# YouTube Videos Table
resource "aws_dynamodb_table" "youtube_videos" {
  name         = "${var.project_name}-youtube-videos-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "video_id"

  attribute {
    name = "video_id"
    type = "S"
  }

  tags = var.tags
}

# Sync Metadata Table
resource "aws_dynamodb_table" "sync_metadata" {
  name         = "${var.project_name}-sync-metadata-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "service_name"

  attribute {
    name = "service_name"
    type = "S"
  }

  tags = var.tags
}
