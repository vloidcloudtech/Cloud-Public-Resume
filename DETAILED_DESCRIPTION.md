# Portfolio Aggregator - Detailed Technical Documentation

## Table of Contents

1. [Overview](#overview)
2. [Architecture Deep Dive](#architecture-deep-dive)
3. [Infrastructure Components](#infrastructure-components)
4. [Backend Implementation](#backend-implementation)
5. [Frontend Implementation](#frontend-implementation)
6. [Data Flow](#data-flow)
7. [Security](#security)
8. [Scalability & Performance](#scalability--performance)
9. [Cost Optimization](#cost-optimization)
10. [Deployment Process](#deployment-process)

---

## Overview

Portfolio Aggregator is a fully serverless application that automatically aggregates content from multiple platforms (GitHub, Medium, YouTube) and presents it through a unified web interface with AI-generated summaries.

### Key Technologies

- **Infrastructure**: Terraform, AWS (Lambda, DynamoDB, API Gateway, S3, CloudFront, EventBridge)
- **Backend**: Python 3.11, Boto3, Anthropic Claude API
- **Frontend**: React 18, Vite, Axios
- **CI/CD**: GitHub Actions
- **Monitoring**: CloudWatch Logs & Metrics

---

## Architecture Deep Dive

### High-Level Architecture

```
┌──────────────────────────────────────────────────────────┐
│                     Internet                             │
└────────────┬─────────────────────────────────────────────┘
             │
┌────────────▼─────────────┐
│ Route 53 (DNS)           │  Custom domain routing
└────────────┬─────────────┘
             │
┌────────────▼─────────────┐
│ CloudFront Distribution  │  CDN + SSL/TLS termination
│ - Global edge caching    │  Price Class: 100 (US, CA, EU)
│ - HTTPS enforcement      │
│ - Custom domain support  │
└────────────┬─────────────┘
             │
       ┌─────▼─────┐
       │           │
  ┌────▼────┐ ┌───▼────┐
  │ S3 (SPA)│ │API GW  │
  └─────────┘ └───┬────┘
                  │
        ┌─────────▼─────────┐
        │ Lambda Functions  │
        │ ┌───────────────┐ │
        │ │ API Handler   │ │  Serves aggregated data
        │ └───────────────┘ │
        │ ┌───────────────┐ │
        │ │ GitHub Sync   │ │  Fetches repos + AI summaries
        │ └───────────────┘ │
        │ ┌───────────────┐ │
        │ │ Medium Sync   │ │  Fetches RSS feed
        │ └───────────────┘ │
        │ ┌───────────────┐ │
        │ │ YouTube Sync  │ │  Fetches videos
        │ └───────────────┘ │
        └─────────┬─────────┘
                  │
        ┌─────────▼─────────┐
        │ DynamoDB Tables   │
        │ - github_repos    │
        │ - medium_posts    │
        │ - youtube_videos  │
        │ - sync_metadata   │
        └───────────────────┘

External APIs:
- GitHub API (repos, README)
- Medium RSS Feed
- YouTube Data API v3
- Anthropic Claude API (AI summaries)
```

### Request Flow

#### Frontend Request (User viewing website)
```
User Browser → CloudFront → S3 → React SPA loaded
React SPA → API Gateway → Lambda (API Handler) → DynamoDB → Response
```

#### Background Sync (EventBridge triggered every 12 hours)
```
EventBridge Schedule → Lambda (Sync Function) → External API → DynamoDB
                                              → Claude API (for GitHub only)
```

---

## Infrastructure Components

### 1. Frontend Module (`terraform/modules/frontend/`)

**Resources:**
- **S3 Bucket**: Hosts static React build
  - Versioning: Disabled
  - Public access: Blocked (CloudFront only)
  - Website hosting: Enabled

- **CloudFront Distribution**:
  - Origin: S3 bucket
  - Price Class: 100 (cost optimization)
  - SSL/TLS: ACM certificate (automatic)
  - Default root object: `index.html`
  - Error handling: SPA routing (404 → index.html)
  - Caching: Default caching behavior

- **Route 53 Records**:
  - A record (root domain) → CloudFront
  - A record (www subdomain) → CloudFront
  - Alias records (no cost for DNS queries)

**Key Configuration:**
```hcl
resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  price_class         = "PriceClass_100"  # US, Canada, Europe only
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.bucket_name}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600   # 1 hour
    max_ttl                = 86400  # 24 hours
  }

  # SPA routing support
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }
}
```

---

### 2. Database Module (`terraform/modules/database/`)

**DynamoDB Tables:**

1. **github_repos**
   - Primary Key: `repo_id` (String)
   - Attributes: name, description, stars, language, url, readme_text, high_level_summary, detailed_summary, summary_hash
   - Billing: On-Demand (PAY_PER_REQUEST)
   - Purpose: Stores GitHub repositories with AI-generated summaries

2. **medium_posts**
   - Primary Key: `post_id` (String, MD5 hash of URL)
   - Attributes: title, summary, published_date, url, read_time
   - Billing: On-Demand
   - Purpose: Stores Medium blog posts from RSS feed

3. **youtube_videos**
   - Primary Key: `video_id` (String)
   - Attributes: title, description, published_date, url, thumbnail, view_count
   - Billing: On-Demand
   - Purpose: Stores YouTube videos

4. **sync_metadata**
   - Primary Key: `service_name` (String: "github" | "medium" | "youtube")
   - Attributes: last_sync_time, last_sync_status, error_message
   - Billing: On-Demand
   - Purpose: Tracks sync job status and timing

**Why On-Demand?**
- Low traffic workload
- Unpredictable read/write patterns
- No need to provision capacity
- Cost-effective for small datasets

---

### 3. API Module (`terraform/modules/api/`)

**Components:**
- API Gateway (HTTP API, not REST API - 70% cheaper)
- Lambda Function (API Handler)
- CloudWatch Log Group (7-day retention)
- IAM Role with DynamoDB read permissions

**API Endpoints:**
```
GET /api/repos          # List all GitHub repositories
GET /api/repos/{id}     # Get single repository with summaries
GET /api/posts          # List all Medium posts
GET /api/videos         # List all YouTube videos
```

**Lambda Configuration:**
- Runtime: Python 3.11
- Memory: 256 MB
- Timeout: 30 seconds
- Layers: Shared code layer (DBClient)
- Environment Variables:
  - GITHUB_REPOS_TABLE
  - MEDIUM_POSTS_TABLE
  - YOUTUBE_VIDEOS_TABLE
  - SYNC_METADATA_TABLE

**IAM Permissions:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ],
      "Resource": ["arn:aws:dynamodb:*:*:table/portfolio-aggregator-*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
```

---

### 4. Sync Module (`terraform/modules/sync/`)

**Components:**
- 3 Lambda Functions (GitHub, Medium, YouTube sync)
- Lambda Layer (shared Python modules)
- EventBridge Rules (12-hour schedules)
- CloudWatch Log Groups (7-day retention)
- IAM Role with DynamoDB write + Secrets Manager read permissions

**Lambda Configurations:**

| Function | Runtime | Memory | Timeout | Triggers |
|----------|---------|--------|---------|----------|
| GitHub Sync | Python 3.11 | 512 MB | 300s (5min) | EventBridge (12h) |
| Medium Sync | Python 3.11 | 256 MB | 60s | EventBridge (12h) |
| YouTube Sync | Python 3.11 | 256 MB | 60s | EventBridge (12h) |

**Why Different Memory/Timeout?**
- GitHub sync needs more resources due to:
  - Multiple API calls (repos + README for each)
  - AI summary generation (Claude API)
  - Larger data processing

**EventBridge Schedule:**
```hcl
resource "aws_cloudwatch_event_rule" "github_sync" {
  name                = "portfolio-aggregator-github-sync-production"
  description         = "Trigger GitHub sync every 12 hours"
  schedule_expression = "rate(12 hours)"
}
```

---

## Backend Implementation

### Lambda Layer Structure

**Purpose**: Share common code across Lambda functions

**Contents** (`backend/shared/`):
- `db_client.py`: DynamoDB operations wrapper
- `api_clients.py`: GitHub, Medium, YouTube API clients

**Layer Structure:**
```
layer.zip/
└── python/
    ├── db_client.py
    └── api_clients.py
```

**Usage in Lambda:**
```python
import sys
sys.path.append('/opt/python')  # Lambda layer path

from db_client import DBClient
from api_clients import GitHubClient
```

---

### GitHub Sync Function

**File**: `backend/lambda_functions/github_sync/handler.py`

**Process Flow:**
1. Fetch all public repositories for specified user
2. For each repository:
   - Get README content
   - Calculate MD5 hash of README
   - If hash changed or no summary exists:
     - Generate AI summaries using Claude 3.5 Sonnet
     - Store both high-level and detailed summaries
   - Update repository data in DynamoDB
3. Update sync metadata with status and timestamp

**AI Summary Generation:**
```python
def generate_summaries(readme_text):
    """Generate high-level and detailed summaries using Claude"""

    # High-level summary (2-3 sentences)
    high_level_prompt = f"""
    Analyze this GitHub repository README and provide a concise
    2-3 sentence summary focusing on:
    - What the project does
    - Key technologies used
    - Main use case

    README:
    {readme_text[:4000]}  # Limit to 4000 chars
    """

    # Detailed summary (technical deep-dive)
    detailed_prompt = f"""
    Provide a detailed technical analysis covering:
    - Architecture and design patterns
    - Key features and capabilities
    - Technical implementation details
    - Dependencies and integrations

    README:
    {readme_text[:8000]}  # Limit to 8000 chars
    """

    # Call Claude API for both summaries
    # Returns: (high_level_summary, detailed_summary)
```

**Optimization**: MD5 hash prevents regenerating summaries for unchanged READMEs (saves on Claude API costs)

---

### Medium Sync Function

**File**: `backend/lambda_functions/medium_sync/handler.py`

**Process Flow:**
1. Fetch RSS feed from Medium
2. Parse XML using `feedparser` library
3. For each post:
   - Extract title, summary, published date, URL
   - Calculate MD5 hash of URL as post_id
   - Estimate read time based on summary length
   - Store in DynamoDB
4. Update sync metadata

**Read Time Calculation:**
```python
def calculate_read_time(summary):
    """Estimate read time (200 words/min average)"""
    word_count = len(summary.split())
    return max(1, round(word_count / 200))
```

---

### YouTube Sync Function

**File**: `backend/lambda_functions/youtube_sync/handler.py`

**Process Flow:**
1. Fetch videos from YouTube Data API v3
2. For each video:
   - Extract metadata (title, description, views, etc.)
   - Get thumbnail URL
   - Store in DynamoDB
3. Update sync metadata

**API Configuration:**
```python
youtube = build('youtube', 'v3', developerKey=api_key)

request = youtube.search().list(
    part='snippet',
    channelId=channel_id,
    maxResults=50,
    order='date',
    type='video'
)
```

---

### API Handler Function

**File**: `backend/lambda_functions/api_handler/handler.py`

**Routing:**
```python
def lambda_handler(event, context):
    path = event.get('rawPath', '')
    method = event.get('requestContext', {}).get('http', {}).get('method', '')

    if path == '/api/repos' and method == 'GET':
        return get_all_repos()
    elif path.startswith('/api/repos/') and method == 'GET':
        repo_id = path.split('/')[-1]
        return get_repo_by_id(repo_id)
    elif path == '/api/posts' and method == 'GET':
        return get_all_posts()
    elif path == '/api/videos' and method == 'GET':
        return get_all_videos()
    else:
        return {
            'statusCode': 404,
            'body': json.dumps({'error': 'Not found'})
        }
```

**CORS Configuration:**
```python
headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',  # CloudFront domain in production
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type'
}
```

---

## Frontend Implementation

### Technology Stack

- **React 18**: Component-based UI
- **Vite**: Build tool (faster than Create React App)
- **React Router**: Client-side routing
- **Axios**: HTTP client for API calls

### Component Structure

```
frontend/src/
├── App.jsx                 # Main app component + routing
├── main.jsx               # Entry point
├── pages/
│   ├── HomePage.jsx       # Landing page
│   ├── GitHubPage.jsx     # GitHub repos list
│   ├── MediumPage.jsx     # Medium posts list
│   └── YouTubePage.jsx    # YouTube videos list
├── services/
│   └── api.js             # API client
└── styles/
    └── index.css          # Global styles
```

### API Service

**File**: `frontend/src/services/api.js`

```javascript
import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL;

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const getRepos = async () => {
  const response = await api.get('/api/repos');
  return response.data;
};

export const getRepoById = async (id) => {
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
```

### Environment Variables

**File**: `frontend/.env`
```
VITE_API_URL=https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com
```

**Note**: Vite requires `VITE_` prefix for environment variables to be exposed to client-side code.

---

## Data Flow

### Sync Flow (Background Process)

```
┌─────────────────┐
│  EventBridge    │  Triggers every 12 hours
└────────┬────────┘
         │
┌────────▼────────┐
│ Lambda (Sync)   │
└────────┬────────┘
         │
    ┌────▼─────┐
    │ Secrets  │  Fetch API keys
    │ Manager  │
    └────┬─────┘
         │
┌────────▼────────┐
│ External API    │  GitHub/Medium/YouTube
└────────┬────────┘
         │
    ┌────▼─────┐  (GitHub only)
    │ Claude   │  Generate AI summaries
    │   API    │
    └────┬─────┘
         │
┌────────▼────────┐
│   DynamoDB      │  Store aggregated data
└─────────────────┘
```

### Read Flow (User Request)

```
┌─────────────────┐
│ User Browser    │
└────────┬────────┘
         │
┌────────▼────────┐
│  CloudFront     │  Edge caching
└────────┬────────┘
         │
    ┌────▼─────┐
    │ React    │  SPA from S3
    │   App    │
    └────┬─────┘
         │
┌────────▼────────┐
│  API Gateway    │
└────────┬────────┘
         │
┌────────▼────────┐
│ Lambda (API)    │
└────────┬────────┘
         │
┌────────▼────────┐
│   DynamoDB      │  Retrieve data
└────────┬────────┘
         │
┌────────▼────────┐
│ User Browser    │  Display data
└─────────────────┘
```

---

## Security

### 1. Secrets Management

**All API keys stored in AWS Secrets Manager:**
- GitHub Personal Access Token
- YouTube Data API Key
- Anthropic Claude API Key

**Format:**
```json
{
  "token": "ghp_xxxxx",
  "api_key": "sk-ant-xxxxx"
}
```

**Lambda Access:**
```python
import boto3
import json

secrets_client = boto3.client('secretsmanager')
secret_value = secrets_client.get_secret_value(SecretId=secret_arn)
secret_data = json.loads(secret_value['SecretString'])
api_key = secret_data['api_key']
```

### 2. IAM Least Privilege

Each Lambda function has minimal permissions:
- API Handler: Read-only DynamoDB access
- Sync Functions: DynamoDB write + Secrets Manager read

### 3. HTTPS Enforcement

- CloudFront redirects all HTTP → HTTPS
- ACM certificate for custom domain (free)
- TLS 1.2+ required

### 4. CORS Configuration

API Gateway CORS settings:
- Allow-Origin: CloudFront distribution domain
- Allow-Methods: GET, OPTIONS only
- Allow-Headers: Content-Type

### 5. S3 Bucket Security

- Public access: Blocked
- Access: CloudFront Origin Access Identity only
- No direct S3 URL access

---

## Scalability & Performance

### Auto-Scaling

**Lambda:**
- Automatic scaling up to 1000 concurrent executions (default)
- No configuration needed

**DynamoDB:**
- On-Demand billing scales automatically
- No capacity planning required

**CloudFront:**
- Global edge network
- Automatic geographic distribution

### Performance Optimizations

1. **CloudFront Caching**
   - Static assets: 24 hours TTL
   - API responses: Not cached (dynamic content)

2. **Lambda Layer**
   - Shared code reduces deployment package size
   - Faster cold starts

3. **DynamoDB Scan Optimization**
   - Limit results to 100 items
   - Sort in DynamoDB (not in Lambda)

4. **AI Summary Caching**
   - MD5 hash prevents regenerating unchanged summaries
   - Saves 80% on Claude API costs

---

## Cost Optimization

### Implemented Optimizations

1. **CloudWatch Logs Retention**: 7 days (vs. infinite)
   - Savings: $2-10/month

2. **CloudFront Price Class 100**: US, Canada, Europe only
   - Savings: 20-30% on data transfer

3. **HTTP API Gateway** (vs. REST API)
   - Savings: 70% ($1/M vs. $3.50/M requests)

4. **DynamoDB On-Demand**: No provisioned capacity
   - Savings: No waste on unused capacity

5. **Lambda Layer**: Shared code reduces package sizes
   - Savings: Faster deployments, lower storage

### Monthly Cost Breakdown

**Fixed Costs:**
- Secrets Manager: $1.20 (3 secrets × $0.40)
- Route 53: $0.50 (hosted zone)
- **Total Fixed**: $1.70/month

**Variable Costs** (usage-based):
- Lambda: FREE (within 1M requests, 400K GB-sec)
- DynamoDB: FREE (within 25 GB, 25 RCU/WCU)
- CloudFront: $0-3/month (first 1TB free)
- CloudWatch Logs: $0-2/month (first 5GB free)
- **Total Variable**: $0-6/month

**Grand Total: $3-8/month**

---

## Deployment Process

### CI/CD Pipeline (GitHub Actions)

**Workflow**: `.github/workflows/deploy.yml`

**Stages:**

1. **Build Lambda Packages**
   - Install Python dependencies
   - Create deployment.zip for each function
   - Build Lambda layer (layer.zip)

2. **Terraform Init & Import**
   - Initialize Terraform
   - Import existing resources (idempotent)

3. **Terraform Apply**
   - Deploy infrastructure changes
   - Update Lambda functions

4. **Populate Secrets**
   - Update AWS Secrets Manager from GitHub Secrets

5. **Deploy Frontend**
   - Build React app (`npm run build`)
   - Sync to S3 bucket
   - Invalidate CloudFront cache

**Trigger**: Push to `main` branch

**Required GitHub Secrets:**
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- GH_PERSONAL_ACCESS_TOKEN
- ANTHROPIC_API_KEY
- YOUTUBE_API_KEY
- GH_USERNAME
- MEDIUM_USERNAME
- YOUTUBE_CHANNEL_ID

---

## Monitoring & Logging

### CloudWatch Logs

**Log Groups:**
- `/aws/lambda/portfolio-aggregator-api-production`
- `/aws/lambda/portfolio-aggregator-github-sync-production`
- `/aws/lambda/portfolio-aggregator-medium-sync-production`
- `/aws/lambda/portfolio-aggregator-youtube-sync-production`

**Retention**: 7 days (cost optimization)

### Metrics

**Lambda Metrics:**
- Invocations
- Duration
- Errors
- Throttles

**DynamoDB Metrics:**
- Read/Write capacity units
- Throttled requests
- System errors

**CloudFront Metrics:**
- Requests
- Data transfer
- 4xx/5xx errors

### Alerting

**CloudWatch Alarm:**
- Metric: EstimatedCharges
- Threshold: $10/month
- Action: SNS topic (email notification)

**Purpose**: Prevent unexpected cost overruns

---

## Conclusion

This architecture provides:
- ✅ **Scalability**: Automatic scaling for all components
- ✅ **Reliability**: Managed services with high SLAs
- ✅ **Cost-Effectiveness**: $3-8/month for full stack
- ✅ **Security**: Secrets Manager, IAM, HTTPS
- ✅ **Performance**: Global CDN, edge caching
- ✅ **Maintainability**: Infrastructure as Code, CI/CD

**Trade-offs:**
- Cold start latency (~1-2s for first request)
- DynamoDB consistency model (eventual consistency)
- CloudFront caching behavior (requires cache invalidation for updates)

**Future Enhancements:**
- Add authentication (Cognito)
- Implement search functionality
- Add analytics tracking
- Multi-region deployment
