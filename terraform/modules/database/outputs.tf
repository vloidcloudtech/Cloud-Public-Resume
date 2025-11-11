output "github_repos_table_name" {
  description = "GitHub repos table name"
  value       = aws_dynamodb_table.github_repos.name
}

output "github_repos_table_arn" {
  description = "GitHub repos table ARN"
  value       = aws_dynamodb_table.github_repos.arn
}

output "medium_posts_table_name" {
  description = "Medium posts table name"
  value       = aws_dynamodb_table.medium_posts.name
}

output "medium_posts_table_arn" {
  description = "Medium posts table ARN"
  value       = aws_dynamodb_table.medium_posts.arn
}

output "youtube_videos_table_name" {
  description = "YouTube videos table name"
  value       = aws_dynamodb_table.youtube_videos.name
}

output "youtube_videos_table_arn" {
  description = "YouTube videos table ARN"
  value       = aws_dynamodb_table.youtube_videos.arn
}

output "sync_metadata_table_name" {
  description = "Sync metadata table name"
  value       = aws_dynamodb_table.sync_metadata.name
}

output "sync_metadata_table_arn" {
  description = "Sync metadata table ARN"
  value       = aws_dynamodb_table.sync_metadata.arn
}
