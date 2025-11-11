output "github_sync_function_name" {
  description = "GitHub sync Lambda function name"
  value       = aws_lambda_function.github_sync.function_name
}

output "medium_sync_function_name" {
  description = "Medium sync Lambda function name"
  value       = aws_lambda_function.medium_sync.function_name
}

output "youtube_sync_function_name" {
  description = "YouTube sync Lambda function name"
  value       = aws_lambda_function.youtube_sync.function_name
}
