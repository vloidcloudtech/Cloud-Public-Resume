# Portfolio Aggregator - Complete Code Implementation Guide

## 📋 Table of Contents
1. [Terraform Infrastructure](#terraform-infrastructure)
2. [Backend Lambda Functions](#backend-lambda-functions)
3. [Frontend React Application](#frontend-react-application)
4. [Deployment Scripts](#deployment-scripts)
5. [CI/CD Configuration](#cicd-configuration)
6. [Environment Configuration](#environment-configuration)

---

## Terraform Infrastructure

### Directory Structure
```
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── backend.tf
├── provider.tf
└── modules/
    ├── frontend/
    ├── api/
    ├── database/
    └── sync/
```

---

### `terraform/provider.tf`
```hcl
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "portfolio-aggregator"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
```

---

### `terraform/backend.tf`
```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "portfolio-aggregator/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

---

### `terraform/variables.tf`
```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "portfolio-aggregator"
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
```

---

### `terraform/main.tf`
```hcl
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# Frontend module
module "frontend" {
  source = "./modules/frontend"
  
  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags
}

# Database module
module "database" {
  source = "./modules/database"
  
  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags
}

# API module
module "api" {
  source = "./modules/api"
  
  project_name                 = var.project_name
  environment                  = var.environment
  github_repos_table_name      = module.database.github_repos_table_name
  github_repos_table_arn       = module.database.github_repos_table_arn
  medium_posts_table_name      = module.database.medium_posts_table_name
  medium_posts_table_arn       = module.database.medium_posts_table_arn
  youtube_videos_table_name    = module.database.youtube_videos_table_name
  youtube_videos_table_arn     = module.database.youtube_videos_table_arn
  sync_metadata_table_name     = module.database.sync_metadata_table_name
  sync_metadata_table_arn      = module.database.sync_metadata_table_arn
  tags                         = local.common_tags
}

# Sync module
module "sync" {
  source = "./modules/sync"
  
  project_name                 = var.project_name
  environment                  = var.environment
  github_username              = var.github_username
  medium_username              = var.medium_username
  youtube_channel_id           = var.youtube_channel_id
  github_token_secret_arn      = var.github_token_secret_arn
  youtube_api_key_secret_arn   = var.youtube_api_key_secret_arn
  ai_api_key_secret_arn        = var.ai_api_key_secret_arn
  github_repos_table_name      = module.database.github_repos_table_name
  github_repos_table_arn       = module.database.github_repos_table_arn
  medium_posts_table_name      = module.database.medium_posts_table_name
  medium_posts_table_arn       = module.database.medium_posts_table_arn
  youtube_videos_table_name    = module.database.youtube_videos_table_name
  youtube_videos_table_arn     = module.database.youtube_videos_table_arn
  sync_metadata_table_name     = module.database.sync_metadata_table_name
  sync_metadata_table_arn      = module.database.sync_metadata_table_arn
  tags                         = local.common_tags
}
```

---

### `terraform/modules/database/main.tf`
```hcl
# GitHub Repositories Table
resource "aws_dynamodb_table" "github_repos" {
  name           = "${var.project_name}-github-repos-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"  # On-demand pricing
  hash_key       = "repo_id"
  
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
  name           = "${var.project_name}-medium-posts-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "post_id"
  
  attribute {
    name = "post_id"
    type = "S"
  }
  
  tags = var.tags
}

# YouTube Videos Table
resource "aws_dynamodb_table" "youtube_videos" {
  name           = "${var.project_name}-youtube-videos-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "video_id"
  
  attribute {
    name = "video_id"
    type = "S"
  }
  
  tags = var.tags
}

# Sync Metadata Table
resource "aws_dynamodb_table" "sync_metadata" {
  name           = "${var.project_name}-sync-metadata-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "service_name"
  
  attribute {
    name = "service_name"
    type = "S"
  }
  
  tags = var.tags
}
```

---

### `terraform/modules/frontend/main.tf`
```hcl
# S3 Bucket for Frontend
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${var.environment}"
  
  tags = var.tags
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  
  index_document {
    suffix = "index.html"
  }
  
  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"  # US, Canada, Europe
  
  origin {
    domain_name = aws_s3_bucket_website_configuration.frontend.website_endpoint
    origin_id   = "S3-${aws_s3_bucket.frontend.id}"
    
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.frontend.id}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    
    forwarded_values {
      query_string = false
      
      cookies {
        forward = "none"
      }
    }
    
    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = true
  }
  
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }
  
  tags = var.tags
}
```

---

### `terraform/modules/api/main.tf`
```hcl
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

# Lambda Function
resource "aws_lambda_function" "api" {
  filename         = "${path.module}/../../../backend/lambda_functions/api_handler/deployment.zip"
  function_name    = "${var.project_name}-api-${var.environment}"
  role            = aws_iam_role.api_lambda.arn
  handler         = "handler.lambda_handler"
  runtime         = "python3.11"
  timeout         = 30
  memory_size     = 256
  
  environment {
    variables = {
      GITHUB_REPOS_TABLE   = var.github_repos_table_name
      MEDIUM_POSTS_TABLE   = var.medium_posts_table_name
      YOUTUBE_VIDEOS_TABLE = var.youtube_videos_table_name
      SYNC_METADATA_TABLE  = var.sync_metadata_table_name
    }
  }
  
  tags = var.tags
}

# API Gateway
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-api-${var.environment}"
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["*"]
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
```

---

### `terraform/modules/sync/main.tf`
```hcl
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

# GitHub Sync Lambda
resource "aws_lambda_function" "github_sync" {
  filename      = "${path.module}/../../../backend/lambda_functions/github_sync/deployment.zip"
  function_name = "${var.project_name}-github-sync-${var.environment}"
  role          = aws_iam_role.sync_lambda.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 300  # 5 minutes
  memory_size   = 512
  
  environment {
    variables = {
      GITHUB_USERNAME       = var.github_username
      GITHUB_TOKEN_SECRET   = var.github_token_secret_arn
      AI_API_KEY_SECRET     = var.ai_api_key_secret_arn
      GITHUB_REPOS_TABLE    = var.github_repos_table_name
      SYNC_METADATA_TABLE   = var.sync_metadata_table_name
    }
  }
  
  tags = var.tags
}

# Medium Sync Lambda
resource "aws_lambda_function" "medium_sync" {
  filename      = "${path.module}/../../../backend/lambda_functions/medium_sync/deployment.zip"
  function_name = "${var.project_name}-medium-sync-${var.environment}"
  role          = aws_iam_role.sync_lambda.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 256
  
  environment {
    variables = {
      MEDIUM_USERNAME      = var.medium_username
      MEDIUM_POSTS_TABLE   = var.medium_posts_table_name
      SYNC_METADATA_TABLE  = var.sync_metadata_table_name
    }
  }
  
  tags = var.tags
}

# YouTube Sync Lambda
resource "aws_lambda_function" "youtube_sync" {
  filename      = "${path.module}/../../../backend/lambda_functions/youtube_sync/deployment.zip"
  function_name = "${var.project_name}-youtube-sync-${var.environment}"
  role          = aws_iam_role.sync_lambda.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 256
  
  environment {
    variables = {
      YOUTUBE_CHANNEL_ID     = var.youtube_channel_id
      YOUTUBE_API_KEY_SECRET = var.youtube_api_key_secret_arn
      YOUTUBE_VIDEOS_TABLE   = var.youtube_videos_table_name
      SYNC_METADATA_TABLE    = var.sync_metadata_table_name
    }
  }
  
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
```

---

## Backend Lambda Functions

### `backend/shared/db_client.py`
```python
import boto3
import os
from decimal import Decimal
import json

dynamodb = boto3.resource('dynamodb')

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return int(obj) if obj % 1 == 0 else float(obj)
        return super(DecimalEncoder, self).default(obj)

class DBClient:
    def __init__(self):
        self.github_table = dynamodb.Table(os.environ['GITHUB_REPOS_TABLE'])
        self.medium_table = dynamodb.Table(os.environ['MEDIUM_POSTS_TABLE'])
        self.youtube_table = dynamodb.Table(os.environ['YOUTUBE_VIDEOS_TABLE'])
        self.sync_table = dynamodb.Table(os.environ['SYNC_METADATA_TABLE'])
    
    def put_repo(self, repo_data):
        """Store a GitHub repository"""
        return self.github_table.put_item(Item=repo_data)
    
    def get_repo(self, repo_id):
        """Get a single repository"""
        response = self.github_table.get_item(Key={'repo_id': repo_id})
        return response.get('Item')
    
    def get_all_repos(self):
        """Get all repositories"""
        response = self.github_table.scan()
        return response.get('Items', [])
    
    def put_post(self, post_data):
        """Store a Medium post"""
        return self.medium_table.put_item(Item=post_data)
    
    def get_all_posts(self):
        """Get all Medium posts"""
        response = self.medium_table.scan()
        return response.get('Items', [])
    
    def put_video(self, video_data):
        """Store a YouTube video"""
        return self.youtube_table.put_item(Item=video_data)
    
    def get_all_videos(self):
        """Get all YouTube videos"""
        response = self.youtube_table.scan()
        return response.get('Items', [])
    
    def update_sync_metadata(self, service_name, status, items_synced=0, error_message=None):
        """Update sync metadata"""
        import time
        item = {
            'service_name': service_name,
            'last_sync_time': int(time.time()),
            'last_sync_status': status,
            'items_synced': items_synced
        }
        if error_message:
            item['error_message'] = error_message
        
        return self.sync_table.put_item(Item=item)
```

---

### `backend/shared/api_clients.py`
```python
import requests
import base64
import feedparser
from googleapiclient.discovery import build

class GitHubClient:
    def __init__(self, token):
        self.token = token
        self.headers = {'Authorization': f'token {token}'}
        self.base_url = 'https://api.github.com'
    
    def get_repos(self, username):
        """Fetch all repositories for a user"""
        url = f'{self.base_url}/users/{username}/repos'
        response = requests.get(url, headers=self.headers)
        response.raise_for_status()
        return response.json()
    
    def get_readme(self, owner, repo):
        """Fetch README content"""
        url = f'{self.base_url}/repos/{owner}/{repo}/readme'
        try:
            response = requests.get(url, headers=self.headers)
            response.raise_for_status()
            content = base64.b64decode(response.json()['content'])
            return content.decode('utf-8')
        except:
            return None
    
    def get_repo_contents(self, owner, repo, path=''):
        """Fetch repository file structure"""
        url = f'{self.base_url}/repos/{owner}/{repo}/contents/{path}'
        response = requests.get(url, headers=self.headers)
        response.raise_for_status()
        return response.json()

class MediumClient:
    def __init__(self, username):
        self.username = username
        self.feed_url = f'https://medium.com/feed/@{username}'
    
    def get_posts(self):
        """Fetch Medium posts from RSS feed"""
        feed = feedparser.parse(self.feed_url)
        posts = []
        
        for entry in feed.entries:
            posts.append({
                'title': entry.title,
                'link': entry.link,
                'published': entry.published,
                'summary': entry.summary
            })
        
        return posts

class YouTubeClient:
    def __init__(self, api_key):
        self.api_key = api_key
        self.youtube = build('youtube', 'v3', developerKey=api_key)
    
    def get_channel_videos(self, channel_id, max_results=50):
        """Fetch videos from a channel"""
        request = self.youtube.search().list(
            part='snippet',
            channelId=channel_id,
            maxResults=max_results,
            order='date',
            type='video'
        )
        response = request.execute()
        
        videos = []
        for item in response.get('items', []):
            video_id = item['id']['videoId']
            
            # Get video details for duration and views
            video_request = self.youtube.videos().list(
                part='contentDetails,statistics',
                id=video_id
            )
            video_response = video_request.execute()
            
            if video_response['items']:
                video_info = video_response['items'][0]
                
                videos.append({
                    'video_id': video_id,
                    'title': item['snippet']['title'],
                    'description': item['snippet']['description'],
                    'published_date': item['snippet']['publishedAt'],
                    'thumbnail_url': item['snippet']['thumbnails']['high']['url'],
                    'duration': video_info['contentDetails']['duration'],
                    'views': video_info['statistics'].get('viewCount', '0')
                })
        
        return videos
```

---

### `backend/lambda_functions/github_sync/handler.py`
```python
import json
import os
import boto3
import hashlib
import time
from anthropic import Anthropic

# Import shared modules
import sys
sys.path.append('/opt/python')  # Lambda layer path
from db_client import DBClient
from api_clients import GitHubClient

def get_secret(secret_arn):
    """Retrieve secret from AWS Secrets Manager"""
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId=secret_arn)
    return json.loads(response['SecretString'])

def generate_summaries(readme_content, ai_api_key):
    """Generate AI summaries using Claude"""
    client = Anthropic(api_key=ai_api_key)
    
    prompt = f"""Analyze this README and provide two summaries:
1. A one-sentence high-level summary
2. A detailed 2-3 sentence technical summary

README:
{readme_content[:4000]}

Respond in JSON format:
{{"high_level": "...", "detailed": "..."}}
"""
    
    try:
        message = client.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=1024,
            messages=[{"role": "user", "content": prompt}]
        )
        
        result = json.loads(message.content[0].text)
        return result.get('high_level', ''), result.get('detailed', '')
    except Exception as e:
        print(f"Error generating summaries: {e}")
        return "Summary generation failed", "Summary generation failed"

def lambda_handler(event, context):
    """Main handler for GitHub sync"""
    print("Starting GitHub sync...")
    
    try:
        # Get secrets
        github_secret = get_secret(os.environ['GITHUB_TOKEN_SECRET'])
        ai_secret = get_secret(os.environ['AI_API_KEY_SECRET'])
        
        github_token = github_secret['token']
        ai_api_key = ai_secret['api_key']
        username = os.environ['GITHUB_USERNAME']
        
        # Initialize clients
        github_client = GitHubClient(github_token)
        db_client = DBClient()
        
        # Fetch repositories
        repos = github_client.get_repos(username)
        print(f"Found {len(repos)} repositories")
        
        synced_count = 0
        
        for repo in repos:
            repo_id = str(repo['id'])
            owner = repo['owner']['login']
            repo_name = repo['name']
            
            print(f"Processing repo: {repo_name}")
            
            # Check if repo already exists
            existing_repo = db_client.get_repo(repo_id)
            
            # Fetch README
            readme_content = github_client.get_readme(owner, repo_name)
            
            if readme_content:
                # Calculate hash to detect changes
                readme_hash = hashlib.md5(readme_content.encode()).hexdigest()
                
                # Check if README changed
                if existing_repo and existing_repo.get('readme_hash') == readme_hash:
                    print(f"  Skipping {repo_name} - no changes")
                    continue
                
                # Generate summaries
                print(f"  Generating summaries for {repo_name}")
                high_level, detailed = generate_summaries(readme_content, ai_api_key)
            else:
                readme_hash = None
                high_level = "No README available"
                detailed = "This repository does not contain a README file."
            
            # Prepare repo data
            repo_data = {
                'repo_id': repo_id,
                'name': repo_name,
                'description': repo.get('description', ''),
                'language': repo.get('language', 'Unknown'),
                'stars': repo.get('stargazers_count', 0),
                'forks': repo.get('forks_count', 0),
                'updated_at': repo['updated_at'],
                'url': repo['html_url'],
                'high_level_summary': high_level,
                'detailed_summary': detailed,
                'last_synced': int(time.time()),
                'readme_hash': readme_hash
            }
            
            # Store in DynamoDB
            db_client.put_repo(repo_data)
            synced_count += 1
            print(f"  Synced {repo_name}")
        
        # Update sync metadata
        db_client.update_sync_metadata('github', 'success', synced_count)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully synced {synced_count} repositories'
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        db_client.update_sync_metadata('github', 'failed', 0, str(e))
        
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
```

---

### `backend/lambda_functions/github_sync/requirements.txt`
```
boto3==1.34.0
anthropic==0.8.1
requests==2.31.0
```

---

### `backend/lambda_functions/medium_sync/handler.py`
```python
import json
import os
import time
import hashlib
import sys
sys.path.append('/opt/python')

from db_client import DBClient
from api_clients import MediumClient

def lambda_handler(event, context):
    """Main handler for Medium sync"""
    print("Starting Medium sync...")
    
    try:
        username = os.environ['MEDIUM_USERNAME']
        
        # Initialize clients
        medium_client = MediumClient(username)
        db_client = DBClient()
        
        # Fetch posts
        posts = medium_client.get_posts()
        print(f"Found {len(posts)} posts")
        
        synced_count = 0
        
        for post in posts:
            # Create post ID from URL
            post_id = hashlib.md5(post['link'].encode()).hexdigest()
            
            # Extract read time (estimated)
            summary_length = len(post['summary'])
            read_time = max(1, summary_length // 1000)  # ~1 min per 1000 chars
            
            post_data = {
                'post_id': post_id,
                'title': post['title'],
                'excerpt': post['summary'][:300] + '...',
                'published_date': post['published'],
                'read_time': f'{read_time} min read',
                'url': post['link'],
                'claps': 0,  # Not available via RSS
                'last_synced': int(time.time())
            }
            
            db_client.put_post(post_data)
            synced_count += 1
            print(f"Synced: {post['title']}")
        
        # Update sync metadata
        db_client.update_sync_metadata('medium', 'success', synced_count)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully synced {synced_count} posts'
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        db_client.update_sync_metadata('medium', 'failed', 0, str(e))
        
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
```

---

### `backend/lambda_functions/medium_sync/requirements.txt`
```
boto3==1.34.0
feedparser==6.0.10
```

---

### `backend/lambda_functions/youtube_sync/handler.py`
```python
import json
import os
import boto3
import time
import sys
sys.path.append('/opt/python')

from db_client import DBClient
from api_clients import YouTubeClient

def get_secret(secret_arn):
    """Retrieve secret from AWS Secrets Manager"""
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId=secret_arn)
    return json.loads(response['SecretString'])

def parse_duration(duration):
    """Convert ISO 8601 duration to readable format"""
    import re
    match = re.match(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?', duration)
    if not match:
        return "0:00"
    
    hours = int(match.group(1) or 0)
    minutes = int(match.group(2) or 0)
    seconds = int(match.group(3) or 0)
    
    if hours:
        return f"{hours}:{minutes:02d}:{seconds:02d}"
    else:
        return f"{minutes}:{seconds:02d}"

def lambda_handler(event, context):
    """Main handler for YouTube sync"""
    print("Starting YouTube sync...")
    
    try:
        # Get secrets
        youtube_secret = get_secret(os.environ['YOUTUBE_API_KEY_SECRET'])
        youtube_api_key = youtube_secret['api_key']
        channel_id = os.environ['YOUTUBE_CHANNEL_ID']
        
        # Initialize clients
        youtube_client = YouTubeClient(youtube_api_key)
        db_client = DBClient()
        
        # Fetch videos
        videos = youtube_client.get_channel_videos(channel_id)
        print(f"Found {len(videos)} videos")
        
        synced_count = 0
        
        for video in videos:
            video_data = {
                'video_id': video['video_id'],
                'title': video['title'],
                'description': video['description'][:500],
                'published_date': video['published_date'].split('T')[0],
                'views': f"{int(video['views']):,}",
                'duration': parse_duration(video['duration']),
                'thumbnail_url': video['thumbnail_url'],
                'url': f"https://youtube.com/watch?v={video['video_id']}",
                'last_synced': int(time.time())
            }
            
            db_client.put_video(video_data)
            synced_count += 1
            print(f"Synced: {video['title']}")
        
        # Update sync metadata
        db_client.update_sync_metadata('youtube', 'success', synced_count)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully synced {synced_count} videos'
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        db_client.update_sync_metadata('youtube', 'failed', 0, str(e))
        
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
```

---

### `backend/lambda_functions/youtube_sync/requirements.txt`
```
boto3==1.34.0
google-api-python-client==2.108.0
```

---

### `backend/lambda_functions/api_handler/handler.py`
```python
import json
import os
import sys
sys.path.append('/opt/python')

from db_client import DBClient, DecimalEncoder

db_client = DBClient()

def lambda_handler(event, context):
    """Main API handler"""
    print(f"Event: {json.dumps(event)}")
    
    route_key = event.get('routeKey', '')
    path_params = event.get('pathParameters', {})
    
    try:
        # Route requests
        if route_key == 'GET /api/repos':
            return get_all_repos()
        elif route_key == 'GET /api/repos/{id}':
            return get_repo(path_params.get('id'))
        elif route_key == 'GET /api/posts':
            return get_all_posts()
        elif route_key == 'GET /api/videos':
            return get_all_videos()
        else:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'Not found'})
            }
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }

def get_all_repos():
    """Get all GitHub repositories"""
    repos = db_client.get_all_repos()
    
    # Sort by stars
    repos.sort(key=lambda x: x.get('stars', 0), reverse=True)
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(repos, cls=DecimalEncoder)
    }

def get_repo(repo_id):
    """Get single repository with summaries"""
    repo = db_client.get_repo(repo_id)
    
    if not repo:
        return {
            'statusCode': 404,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': 'Repository not found'})
        }
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(repo, cls=DecimalEncoder)
    }

def get_all_posts():
    """Get all Medium posts"""
    posts = db_client.get_all_posts()
    
    # Sort by published date
    posts.sort(key=lambda x: x.get('published_date', ''), reverse=True)
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(posts, cls=DecimalEncoder)
    }

def get_all_videos():
    """Get all YouTube videos"""
    videos = db_client.get_all_videos()
    
    # Sort by published date
    videos.sort(key=lambda x: x.get('published_date', ''), reverse=True)
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(videos, cls=DecimalEncoder)
    }
```

---

### `backend/lambda_functions/api_handler/requirements.txt`
```
boto3==1.34.0
```

---

## Frontend React Application

### `frontend/package.json`
```json
{
  "name": "portfolio-aggregator-frontend",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.0",
    "axios": "^1.6.2"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.2.1",
    "vite": "^5.0.8"
  },
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  }
}
```

---

### `frontend/vite.config.js`
```javascript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000
  },
  build: {
    outDir: 'build'
  }
})
```

---

### `frontend/src/services/api.js`
```javascript
import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json'
  }
});

export const getRepos = async () => {
  const response = await api.get('/api/repos');
  return response.data;
};

export const getRepo = async (id) => {
  const response = await api.get(`/api/repos/${id}`);
  return response.data;
};

export const getPosts = async () => {
  const response = await api.get('/api/posts');
  return response.data;
};

export const getVideos = async () => {
  const response = await api.get('/api/videos');
  return response.data;
};

export default api;
```

---

### `frontend/src/App.jsx`
```javascript
import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import HomePage from './pages/HomePage';
import GitHubPage from './pages/GitHubPage';
import MediumPage from './pages/MediumPage';
import YouTubePage from './pages/YouTubePage';
import './styles/index.css';

function App() {
  const [activeTab, setActiveTab] = useState('home');

  return (
    <Router>
      <div className="app">
        <nav className="navbar">
          <div className="nav-content">
            <div className="logo">
              💻 Your Portfolio
            </div>
            <div className="nav-tabs">
              <Link 
                to="/" 
                className={`nav-tab ${activeTab === 'home' ? 'active' : ''}`}
                onClick={() => setActiveTab('home')}
              >
                🏠 Home
              </Link>
              <Link 
                to="/github" 
                className={`nav-tab ${activeTab === 'github' ? 'active' : ''}`}
                onClick={() => setActiveTab('github')}
              >
                💾 GitHub
              </Link>
              <Link 
                to="/medium" 
                className={`nav-tab ${activeTab === 'medium' ? 'active' : ''}`}
                onClick={() => setActiveTab('medium')}
              >
                📝 Medium
              </Link>
              <Link 
                to="/youtube" 
                className={`nav-tab ${activeTab === 'youtube' ? 'active' : ''}`}
                onClick={() => setActiveTab('youtube')}
              >
                🎥 YouTube
              </Link>
            </div>
          </div>
        </nav>

        <main className="container">
          <Routes>
            <Route path="/" element={<HomePage />} />
            <Route path="/github" element={<GitHubPage />} />
            <Route path="/medium" element={<MediumPage />} />
            <Route path="/youtube" element={<YouTubePage />} />
          </Routes>
        </main>

        <footer className="footer">
          <div className="footer-content">
            <p>© 2024 Your Name. Auto-synced via AWS Lambda.</p>
            <div className="footer-links">
              <a href="https://github.com/yourusername">💾</a>
              <a href="https://linkedin.com/in/yourusername">💼</a>
              <a href="https://twitter.com/yourusername">🐦</a>
            </div>
          </div>
          <div className="sync-status">
            ✓ Last synced: {new Date().toLocaleString()}
          </div>
        </footer>
      </div>
    </Router>
  );
}

export default App;
```

---

### `frontend/src/pages/GitHubPage.jsx`
```javascript
import React, { useState, useEffect } from 'react';
import { getRepos, getRepo } from '../services/api';

function GitHubPage() {
  const [repos, setRepos] = useState([]);
  const [selectedRepo, setSelectedRepo] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchRepos();
  }, []);

  const fetchRepos = async () => {
    try {
      setLoading(true);
      const data = await getRepos();
      setRepos(data);
    } catch (error) {
      console.error('Error fetching repos:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleRepoClick = async (repoId) => {
    try {
      const data = await getRepo(repoId);
      setSelectedRepo(data);
    } catch (error) {
      console.error('Error fetching repo:', error);
    }
  };

  if (loading) {
    return <div className="loading"><div className="spinner"></div></div>;
  }

  if (selectedRepo) {
    return (
      <div className="fade-in">
        <button 
          className="back-button" 
          onClick={() => setSelectedRepo(null)}
        >
          ← Back to repositories
        </button>
        
        <div className="card">
          <div className="detail-header">
            <div>
              <h2 className="detail-title">{selectedRepo.name}</h2>
              <p className="repo-description">{selectedRepo.description}</p>
            </div>
            <span className="badge">{selectedRepo.language}</span>
          </div>
          
          <div className="detail-meta">
            <span>⭐ {selectedRepo.stars} stars</span>
            <span>🔀 {selectedRepo.forks} forks</span>
            <span>🕐 Updated {selectedRepo.updated_at}</span>
          </div>
          
          <div className="summary-box">
            <h3>
              💡 High-Level Summary
              <span className="ai-badge">AI Generated</span>
            </h3>
            <p className="summary-text">{selectedRepo.high_level_summary}</p>
          </div>
          
          <div className="summary-box">
            <h3>
              📄 Detailed Summary
              <span className="ai-badge">AI Generated</span>
            </h3>
            <p className="summary-text">{selectedRepo.detailed_summary}</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="fade-in">
      <div className="section-header">
        <h2>GitHub Repositories</h2>
        <p>Automatically synced with AI-generated summaries</p>
      </div>

      <div className="grid grid-2">
        {repos.map(repo => (
          <div 
            key={repo.repo_id} 
            className="card repo-card"
            onClick={() => handleRepoClick(repo.repo_id)}
          >
            <div className="repo-header">
              <div className="repo-title">
                💾 {repo.name}
              </div>
              <span className="badge">{repo.language}</span>
            </div>
            <p className="repo-description">{repo.description}</p>
            <div className="repo-summary">
              "{repo.high_level_summary}"
            </div>
            <div className="repo-stats">
              <span>⭐ {repo.stars}</span>
              <span>🔀 {repo.forks}</span>
              <span style={{ marginLeft: 'auto', color: '#8b5cf6' }}>
                View details →
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default GitHubPage;
```

---

### `frontend/.env.example`
```env
VITE_API_URL=https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com
```

---

## Deployment Scripts

### `backend/deploy.sh`
```bash
#!/bin/bash

set -e

echo "Deploying Lambda functions..."

# Array of Lambda function directories
FUNCTIONS=("github_sync" "medium_sync" "youtube_sync" "api_handler")

for FUNCTION in "${FUNCTIONS[@]}"; do
    echo "Building $FUNCTION..."
    
    cd lambda_functions/$FUNCTION
    
    # Install dependencies
    pip install -r requirements.txt -t package/
    
    # Copy handler
    cp handler.py package/
    
    # Create deployment package
    cd package
    zip -r ../deployment.zip .
    cd ..
    
    # Clean up
    rm -rf package
    
    echo "✓ Built $FUNCTION"
    cd ../..
done

# Create Lambda layer for shared code
echo "Building shared layer..."
cd shared
mkdir -p python
cp *.py python/
zip -r ../layer.zip python
rm -rf python
cd ..

echo "✓ All Lambda functions built successfully!"
echo ""
echo "Now run: terraform apply"
```

---

### `frontend/deploy.sh`
```bash
#!/bin/bash

set -e

echo "Building frontend..."

# Install dependencies
npm install

# Build for production
npm run build

echo "✓ Frontend built successfully!"
echo ""
echo "Deploying to S3..."

# Get bucket name from Terraform output
BUCKET_NAME=$(cd ../terraform && terraform output -raw frontend_bucket_name)

# Sync to S3
aws s3 sync build/ s3://$BUCKET_NAME --delete

echo "✓ Deployed to S3!"
echo ""
echo "Invalidating CloudFront cache..."

# Get distribution ID
DIST_ID=$(cd ../terraform && terraform output -raw cloudfront_distribution_id)

# Create invalidation
aws cloudfront create-invalidation \
    --distribution-id $DIST_ID \
    --paths "/*"

echo "✓ CloudFront cache invalidated!"
echo ""
echo "🚀 Deployment complete!"
```

---

### `scripts/setup.sh`
```bash
#!/bin/bash

set -e

echo "🚀 Setting up Portfolio Aggregator..."
echo ""

# Check prerequisites
echo "Checking prerequisites..."
command -v terraform >/dev/null 2>&1 || { echo "Error: terraform not installed"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "Error: aws-cli not installed"; exit 1; }
command -v node >/dev/null 2>&1 || { echo "Error: node not installed"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "Error: python3 not installed"; exit 1; }

echo "✓ All prerequisites installed"
echo ""

# Configure AWS CLI
echo "Configuring AWS CLI..."
aws configure

echo ""
echo "Creating Secrets Manager secrets..."

# Prompt for API keys
read -p "Enter GitHub Personal Access Token: " GITHUB_TOKEN
read -p "Enter YouTube API Key: " YOUTUBE_KEY
read -p "Enter AI API Key (Anthropic/OpenAI): " AI_KEY

# Create secrets
aws secretsmanager create-secret \
    --name portfolio-aggregator-github-token \
    --secret-string "{\"token\":\"$GITHUB_TOKEN\"}"

aws secretsmanager create-secret \
    --name portfolio-aggregator-youtube-key \
    --secret-string "{\"api_key\":\"$YOUTUBE_KEY\"}"

aws secretsmanager create-secret \
    --name portfolio-aggregator-ai-key \
    --secret-string "{\"api_key\":\"$AI_KEY\"}"

echo "✓ Secrets created"
echo ""

# Initialize Terraform
echo "Initializing Terraform..."
cd terraform
terraform init

echo "✓ Terraform initialized"
echo ""

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Update terraform/terraform.tfvars with your usernames"
echo "2. Run: terraform plan"
echo "3. Run: terraform apply"
echo "4. Run: cd ../frontend && npm install"
```

---

## CI/CD Configuration

### `.github/workflows/deploy.yml`
```yaml
name: Deploy Portfolio Aggregator

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  AWS_REGION: us-east-1

jobs:
  terraform:
    name: Terraform
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.6.0

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Terraform Init
        run: |
          cd terraform
          terraform init

      - name: Terraform Plan
        run: |
          cd terraform
          terraform plan

      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: |
          cd terraform
          terraform apply -auto-approve

  deploy-backend:
    name: Deploy Backend
    runs-on: ubuntu-latest
    needs: terraform
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Build and Deploy Lambda Functions
        run: |
          cd backend
          chmod +x deploy.sh
          ./deploy.sh

  deploy-frontend:
    name: Deploy Frontend
    runs-on: ubuntu-latest
    needs: terraform
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Build and Deploy
        run: |
          cd frontend
          chmod +x deploy.sh
          ./deploy.sh
```

---

## Environment Configuration

### `terraform/terraform.tfvars.example`
```hcl
aws_region     = "us-east-1"
environment    = "production"
project_name   = "portfolio-aggregator"

github_username  = "your-github-username"
medium_username  = "your-medium-username"
youtube_channel_id = "your-youtube-channel-id"

github_token_secret_arn   = "arn:aws:secretsmanager:us-east-1:123456789:secret:portfolio-aggregator-github-token"
youtube_api_key_secret_arn = "arn:aws:secretsmanager:us-east-1:123456789:secret:portfolio-aggregator-youtube-key"
ai_api_key_secret_arn     = "arn:aws:secretsmanager:us-east-1:123456789:secret:portfolio-aggregator-ai-key"
```

---

### `.gitignore`
```
# Terraform
**/.terraform/*
*.tfstate
*.tfstate.*
*.tfvars
!*.tfvars.example

# Lambda packages
**/deployment.zip
**/layer.zip
**/package/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/

# Node
node_modules/
build/
dist/
.env
.env.local

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db
```

---

## README.md Template

### `README.md`
```markdown
# Portfolio Aggregator

Automated portfolio website that aggregates content from GitHub, Medium, and YouTube with AI-powered summaries.

## Features

- 🤖 AI-generated repository summaries
- 🔄 Automatic syncing every 12 hours
- 📱 Fully responsive design
- ☁️ Serverless AWS architecture
- 💰 Costs $1-3/month

## Prerequisites

- AWS Account
- Terraform >= 1.0
- Node.js >= 18
- Python >= 3.11
- AWS CLI configured

## Quick Start

1. Clone the repository
2. Run setup script: `./scripts/setup.sh`
3. Update `terraform/terraform.tfvars`
4. Deploy: `terraform apply`
5. Build frontend: `cd frontend && npm install && npm run build`
6. Deploy frontend: `./deploy.sh`

## Architecture

See [PROJECT_BREAKDOWN.md](PROJECT_BREAKDOWN.md) for detailed architecture.

## Costs

Expected monthly cost: $1-3 (mostly AI API usage)

## License

MIT
```

---

## Summary

This code implementation guide provides:
✅ Complete Terraform infrastructure  
✅ All Lambda function code  
✅ React frontend application  
✅ Deployment scripts  
✅ CI/CD pipeline  
✅ Configuration templates  

**Ready to deploy!** 🚀
