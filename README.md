# Portfolio Aggregator

**Automated serverless portfolio website** that aggregates and displays content from GitHub, Medium, and YouTube with AI-generated summaries.

[![AWS](https://img.shields.io/badge/AWS-Serverless-orange)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/Terraform-Infrastructure-purple)](https://www.terraform.io/)
[![React](https://img.shields.io/badge/React-Frontend-blue)](https://reactjs.org/)

---

## ✨ Features

- 🤖 **AI-Powered Summaries** - Automatic README summaries using Claude 3.5 Sonnet
- 🔄 **Auto-Sync** - Content updates every 12 hours via EventBridge
- 📱 **Responsive Design** - Mobile-first React frontend
- ☁️ **Serverless Architecture** - 100% serverless on AWS
- 💰 **Cost-Effective** - Runs for $3-8/month
- 🚀 **CI/CD** - Automated deployments via GitHub Actions

---

## 🏗️ Architecture

```
┌─────────────┐
│ CloudFront  │  CDN + SSL/TLS
└──────┬──────┘
       │
┌──────▼──────┐
│  S3 Bucket  │  React SPA
└──────┬──────┘
       │
┌──────▼──────────┐
│  API Gateway    │  HTTP API
└──────┬──────────┘
       │
┌──────▼────────────────────────┐
│  Lambda Functions             │
│  ├── API Handler              │
│  ├── GitHub Sync (+ Claude)   │
│  ├── Medium Sync              │
│  └── YouTube Sync             │
└──────┬────────────────────────┘
       │
┌──────▼──────┐
│  DynamoDB   │  NoSQL Database
└─────────────┘
```

---

## 🚀 Quick Start

### Prerequisites

- AWS Account
- Terraform >= 1.6
- Node.js >= 18
- Python >= 3.11
- GitHub Personal Access Token
- YouTube Data API Key
- Anthropic API Key

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/Cloud-Public-Resume.git
cd Cloud-Public-Resume
```

### 2. Configure Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 3. Set GitHub Secrets

Required secrets for CI/CD:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `GH_PERSONAL_ACCESS_TOKEN`
- `ANTHROPIC_API_KEY`
- `YOUTUBE_API_KEY`
- `GH_USERNAME`
- `MEDIUM_USERNAME`
- `YOUTUBE_CHANNEL_ID`

### 4. Deploy via GitHub Actions

```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

GitHub Actions will automatically:
1. Build Lambda functions and layer
2. Deploy infrastructure via Terraform
3. Populate secrets
4. Deploy frontend to S3/CloudFront

---

## 📖 Documentation

- **[DETAILED_DESCRIPTION.md](./DETAILED_DESCRIPTION.md)** - Complete technical documentation
- **[CODE_IMPLEMENTATION.md](./CODE_IMPLEMENTATION.md)** - Code structure and implementation details
- **[PROJECT_BREAKDOWN.md](./PROJECT_BREAKDOWN.md)** - Project analysis and breakdown
- **[docs/guides/](./docs/guides/)** - Setup guides and troubleshooting

---

## 💰 Cost Breakdown

**Monthly Costs:**
- **Fixed**: $1.70/month
  - Secrets Manager: $1.20 (3 secrets × $0.40)
  - Route 53: $0.50 (hosted zone)

- **Variable**: $0-6/month (depends on traffic)
  - Lambda, DynamoDB, CloudFront (mostly free tier)
  - CloudWatch Logs (7-day retention)

**Total Estimate**: $3-8/month

See [docs/guides/COST_MANAGEMENT.md](./docs/guides/COST_MANAGEMENT.md) for details.

---

## 🛠️ Tech Stack

**Infrastructure:**
- Terraform (IaC)
- AWS Lambda (Python 3.11)
- DynamoDB (NoSQL)
- API Gateway (HTTP API)
- S3 + CloudFront
- EventBridge (Scheduler)
- Secrets Manager
- CloudWatch Logs

**Frontend:**
- React 18
- Vite
- Axios
- React Router

**Backend:**
- Python 3.11
- Boto3 (AWS SDK)
- Anthropic Claude API
- GitHub API
- Medium RSS Feed
- YouTube Data API v3

**CI/CD:**
- GitHub Actions
- Terraform Cloud (optional)

---

## 📁 Project Structure

```
Cloud-Public-Resume/
├── .github/workflows/     # GitHub Actions CI/CD
├── backend/
│   ├── lambda_functions/  # Lambda handlers
│   ├── shared/           # Shared Python modules
│   └── layer.zip         # Lambda layer
├── frontend/             # React SPA
├── terraform/            # Infrastructure as Code
│   ├── modules/         # Terraform modules
│   └── *.tf             # Root configuration
├── scripts/             # Utility scripts
├── docs/guides/         # Setup and troubleshooting guides
└── README.md           # This file
```

---

## 🔧 Development

### Local Testing

```bash
# Backend
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# Frontend
cd frontend
npm install
npm run dev
```

### Manual Sync

Trigger sync functions manually:

```bash
# Via GitHub Actions
Go to Actions → Manual Sync Data → Run workflow

# Or via AWS CLI
aws lambda invoke --function-name portfolio-aggregator-github-sync-production output.json
```

---



## 📜 License

MIT License - See [LICENSE](./LICENSE) for details

---


