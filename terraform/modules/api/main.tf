# Lambda Execution Role
resource "aws_iam_role" "api_lambda" {
  name = "${var.project_name}-api-lambda-role-${var.environment}"

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

# Lambda Policy
resource "aws_iam_role_policy" "api_lambda" {
  name = "${var.project_name}-api-lambda-policy"
  role = aws_iam_role.api_lambda.id

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
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          var.github_repos_table_arn,
          var.medium_posts_table_arn,
          var.youtube_videos_table_arn,
          var.sync_metadata_table_arn
        ]
      }
    ]
  })
}

# CloudWatch Log Group (with retention to prevent unbounded growth)
resource "aws_cloudwatch_log_group" "api_lambda" {
  name              = "/aws/lambda/${var.project_name}-api-${var.environment}"
  retention_in_days = 7  # Logs retained for 7 days (cost optimization)

  tags = var.tags
}

# Lambda Function
resource "aws_lambda_function" "api" {
  filename         = "${path.module}/../../../backend/lambda_functions/api_handler/deployment.zip"
  function_name    = "${var.project_name}-api-${var.environment}"
  role             = aws_iam_role.api_lambda.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 256
  source_code_hash = filebase64sha256("${path.module}/../../../backend/lambda_functions/api_handler/deployment.zip")

  environment {
    variables = {
      GITHUB_REPOS_TABLE   = var.github_repos_table_name
      MEDIUM_POSTS_TABLE   = var.medium_posts_table_name
      YOUTUBE_VIDEOS_TABLE = var.youtube_videos_table_name
      SYNC_METADATA_TABLE  = var.sync_metadata_table_name
    }
  }

  layers = [var.shared_layer_arn]

  # Ensure log group exists before Lambda function
  depends_on = [aws_cloudwatch_log_group.api_lambda]

  tags = var.tags
}

# API Gateway
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-api-${var.environment}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    expose_headers = ["*"]
    max_age = 300
  }

  tags = var.tags
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"

  integration_uri    = aws_lambda_function.api.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "repos" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /api/repos"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "repo_detail" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /api/repos/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "posts" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /api/posts"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "videos" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /api/videos"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
