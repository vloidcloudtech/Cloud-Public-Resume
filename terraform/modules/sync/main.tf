# IAM Role for Sync Lambdas
resource "aws_iam_role" "sync_lambda" {
  name = "${var.project_name}-sync-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "sync_lambda" {
  name = "${var.project_name}-sync-lambda-policy"
  role = aws_iam_role.sync_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          var.github_repos_table_arn,
          var.medium_posts_table_arn,
          var.youtube_videos_table_arn,
          var.sync_metadata_table_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          var.github_token_secret_arn,
          var.youtube_api_key_secret_arn,
          var.ai_api_key_secret_arn
        ]
      }
    ]
  })
}

# CloudWatch Log Groups (with retention to prevent unbounded growth)
resource "aws_cloudwatch_log_group" "github_sync" {
  name              = "/aws/lambda/${var.project_name}-github-sync-${var.environment}"
  retention_in_days = 7  # Logs retained for 7 days (cost optimization)

  tags = var.tags

  lifecycle {
    ignore_changes = [name]  # Ignore if already exists
  }
}

resource "aws_cloudwatch_log_group" "medium_sync" {
  name              = "/aws/lambda/${var.project_name}-medium-sync-${var.environment}"
  retention_in_days = 7

  tags = var.tags

  lifecycle {
    ignore_changes = [name]  # Ignore if already exists
  }
}

resource "aws_cloudwatch_log_group" "youtube_sync" {
  name              = "/aws/lambda/${var.project_name}-youtube-sync-${var.environment}"
  retention_in_days = 7

  tags = var.tags

  lifecycle {
    ignore_changes = [name]  # Ignore if already exists
  }
}

# Lambda Layer for Shared Code
resource "aws_lambda_layer_version" "shared" {
  filename            = "${path.module}/../../../backend/layer.zip"
  layer_name          = "${var.project_name}-shared-layer-${var.environment}"
  compatible_runtimes = ["python3.11"]

  source_code_hash = filebase64sha256("${path.module}/../../../backend/layer.zip")
}

# GitHub Sync Lambda
resource "aws_lambda_function" "github_sync" {
  filename         = "${path.module}/../../../backend/lambda_functions/github_sync/deployment.zip"
  function_name    = "${var.project_name}-github-sync-${var.environment}"
  role             = aws_iam_role.sync_lambda.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 300 # 5 minutes
  memory_size      = 512
  source_code_hash = filebase64sha256("${path.module}/../../../backend/lambda_functions/github_sync/deployment.zip")

  environment {
    variables = {
      GITHUB_USERNAME     = var.github_username
      GITHUB_TOKEN_SECRET = var.github_token_secret_arn
      AI_API_KEY_SECRET   = var.ai_api_key_secret_arn
      GITHUB_REPOS_TABLE  = var.github_repos_table_name
      SYNC_METADATA_TABLE = var.sync_metadata_table_name
    }
  }

  layers = [aws_lambda_layer_version.shared.arn]

  depends_on = [aws_cloudwatch_log_group.github_sync]

  tags = var.tags
}

# Medium Sync Lambda
resource "aws_lambda_function" "medium_sync" {
  filename         = "${path.module}/../../../backend/lambda_functions/medium_sync/deployment.zip"
  function_name    = "${var.project_name}-medium-sync-${var.environment}"
  role             = aws_iam_role.sync_lambda.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 60
  memory_size      = 256
  source_code_hash = filebase64sha256("${path.module}/../../../backend/lambda_functions/medium_sync/deployment.zip")

  environment {
    variables = {
      MEDIUM_USERNAME     = var.medium_username
      MEDIUM_POSTS_TABLE  = var.medium_posts_table_name
      SYNC_METADATA_TABLE = var.sync_metadata_table_name
    }
  }

  layers = [aws_lambda_layer_version.shared.arn]

  depends_on = [
    aws_cloudwatch_log_group.medium_sync,
    aws_lambda_function.github_sync  # Wait for github_sync to finish updating
  ]

  tags = var.tags
}

# YouTube Sync Lambda
resource "aws_lambda_function" "youtube_sync" {
  filename         = "${path.module}/../../../backend/lambda_functions/youtube_sync/deployment.zip"
  function_name    = "${var.project_name}-youtube-sync-${var.environment}"
  role             = aws_iam_role.sync_lambda.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 60
  memory_size      = 256
  source_code_hash = filebase64sha256("${path.module}/../../../backend/lambda_functions/youtube_sync/deployment.zip")

  environment {
    variables = {
      YOUTUBE_CHANNEL_ID     = var.youtube_channel_id
      YOUTUBE_API_KEY_SECRET = var.youtube_api_key_secret_arn
      YOUTUBE_VIDEOS_TABLE   = var.youtube_videos_table_name
      SYNC_METADATA_TABLE    = var.sync_metadata_table_name
    }
  }

  layers = [aws_lambda_layer_version.shared.arn]

  depends_on = [
    aws_cloudwatch_log_group.youtube_sync,
    aws_lambda_function.medium_sync  # Wait for medium_sync to finish updating
  ]

  tags = var.tags
}

# EventBridge Rules
resource "aws_cloudwatch_event_rule" "github_sync" {
  name                = "${var.project_name}-github-sync-${var.environment}"
  description         = "Trigger GitHub sync every 12 hours"
  schedule_expression = "rate(12 hours)"

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "github_sync" {
  rule      = aws_cloudwatch_event_rule.github_sync.name
  target_id = "GithubSyncLambda"
  arn       = aws_lambda_function.github_sync.arn
}

resource "aws_lambda_permission" "github_sync_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.github_sync.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.github_sync.arn
}

resource "aws_cloudwatch_event_rule" "medium_sync" {
  name                = "${var.project_name}-medium-sync-${var.environment}"
  description         = "Trigger Medium sync every 12 hours"
  schedule_expression = "rate(12 hours)"

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "medium_sync" {
  rule      = aws_cloudwatch_event_rule.medium_sync.name
  target_id = "MediumSyncLambda"
  arn       = aws_lambda_function.medium_sync.arn
}

resource "aws_lambda_permission" "medium_sync_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.medium_sync.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.medium_sync.arn
}

resource "aws_cloudwatch_event_rule" "youtube_sync" {
  name                = "${var.project_name}-youtube-sync-${var.environment}"
  description         = "Trigger YouTube sync every 12 hours"
  schedule_expression = "rate(12 hours)"

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "youtube_sync" {
  rule      = aws_cloudwatch_event_rule.youtube_sync.name
  target_id = "YoutubeSyncLambda"
  arn       = aws_lambda_function.youtube_sync.arn
}

resource "aws_lambda_permission" "youtube_sync_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.youtube_sync.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.youtube_sync.arn
}
