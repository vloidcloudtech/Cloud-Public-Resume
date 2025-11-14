"""
================================================================================
GitHub Sync Lambda Function
================================================================================
This Lambda function synchronizes GitHub repositories and generates AI-powered
summaries for each repository using Claude (Anthropic API).

Trigger: EventBridge schedule (every 12 hours)
Runtime: Python 3.11
Timeout: 5 minutes (300 seconds)
Memory: 512 MB

Environment Variables:
    - GITHUB_USERNAME: GitHub username to fetch repos from
    - GITHUB_TOKEN_SECRET: ARN of GitHub token in Secrets Manager
    - AI_API_KEY_SECRET: ARN of Anthropic API key in Secrets Manager
    - GITHUB_REPOS_TABLE: DynamoDB table name for storing repos
    - SYNC_METADATA_TABLE: DynamoDB table name for sync metadata

External Dependencies:
    - GitHub API v3: For fetching repositories and README files
    - Anthropic API: For generating AI summaries using Claude
    - AWS Secrets Manager: For securely storing API keys
    - AWS DynamoDB: For storing repository data
================================================================================
"""

import json
import os
import boto3
import hashlib
import time
import requests

# ============================================================================
# Import Shared Modules from Lambda Layer
# ============================================================================
# Lambda layers are mounted at /opt, so we add /opt/python to the path
import sys
sys.path.append('/opt/python')  # Lambda layer path for shared modules
from db_client import DBClient
from api_clients import GitHubClient

# ============================================================================
# Helper Functions
# ============================================================================

def get_secret(secret_arn):
    """
    Retrieve a secret value from AWS Secrets Manager.

    Args:
        secret_arn (str): ARN of the secret in Secrets Manager

    Returns:
        dict: Parsed JSON secret value

    Raises:
        ClientError: If secret cannot be retrieved
    """
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId=secret_arn)
    return json.loads(response['SecretString'])


def generate_summaries(readme_content, ai_api_key):
    """
    Generate AI-powered summaries of a GitHub repository README using Claude.

    This function uses Claude 3.5 Sonnet to analyze README content and generate
    two types of summaries:
    1. High-level: One-sentence overview for quick scanning
    2. Detailed: 2-3 sentence technical summary with more depth

    Args:
        readme_content (str): Raw README content (markdown)
        ai_api_key (str): Anthropic API key for Claude access

    Returns:
        tuple: (high_level_summary, detailed_summary) as strings

    Note:
        - README content is truncated to 4000 chars to stay within token limits
        - Falls back to error message if API call fails
        - Model: claude-3-5-sonnet-20241022 (latest Sonnet version)
    """
    # Construct the prompt for Claude
    prompt = f"""Analyze this README and provide two summaries:
1. A one-sentence high-level summary
2. A detailed 2-3 sentence technical summary

README:
{readme_content[:4000]}

Respond in JSON format:
{{"high_level": "...", "detailed": "..."}}
"""

    try:
        # Call Claude API directly using requests to avoid SDK issues
        headers = {
            "x-api-key": ai_api_key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json"
        }

        payload = {
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 1024,
            "messages": [{"role": "user", "content": prompt}]
        }

        response = requests.post(
            "https://api.anthropic.com/v1/messages",
            headers=headers,
            json=payload,
            timeout=30
        )
        response.raise_for_status()

        # Parse the JSON response
        message = response.json()
        result = json.loads(message['content'][0]['text'])
        return result.get('high_level', ''), result.get('detailed', '')

    except Exception as e:
        # Log the error and return fallback messages
        print(f"Error generating summaries: {e}")
        return "Summary generation failed", "Summary generation failed"

# ============================================================================
# Main Lambda Handler
# ============================================================================

def lambda_handler(event, context):
    """
    Main Lambda handler for synchronizing GitHub repositories.

    This function:
    1. Retrieves API keys from AWS Secrets Manager
    2. Fetches all repositories for the configured GitHub user
    3. For each repository:
       - Checks if it already exists in DynamoDB
       - Fetches the README file
       - Calculates MD5 hash to detect changes
       - Generates AI summaries (if README changed or new repo)
       - Stores/updates repository data in DynamoDB
    4. Updates sync metadata with results

    Args:
        event (dict): EventBridge event (empty for scheduled events)
        context (LambdaContext): Lambda execution context

    Returns:
        dict: HTTP-style response with statusCode and body

    Environment Variables Required:
        - GITHUB_USERNAME: GitHub username to sync
        - GITHUB_TOKEN_SECRET: ARN of GitHub PAT in Secrets Manager
        - AI_API_KEY_SECRET: ARN of Anthropic API key in Secrets Manager
        - GITHUB_REPOS_TABLE: DynamoDB table name
        - SYNC_METADATA_TABLE: DynamoDB table name
    """
    print("Starting GitHub sync...")

    try:
        # ------------------------------------------------------------------------
        # Step 1: Retrieve API keys from AWS Secrets Manager
        # ------------------------------------------------------------------------
        # Secrets are stored in Secrets Manager for security
        # Format: {"token": "ghp_..."} and {"api_key": "sk-..."}

        github_secret = get_secret(os.environ['GITHUB_TOKEN_SECRET'])
        ai_secret = get_secret(os.environ['AI_API_KEY_SECRET'])

        github_token = github_secret['token']
        ai_api_key = ai_secret['api_key']
        username = os.environ['GITHUB_USERNAME']

        # ------------------------------------------------------------------------
        # Step 2: Initialize API clients
        # ------------------------------------------------------------------------

        github_client = GitHubClient(github_token)
        db_client = DBClient()

        # ------------------------------------------------------------------------
        # Step 3: Fetch all repositories for the user
        # ------------------------------------------------------------------------

        repos = github_client.get_repos(username)
        print(f"Found {len(repos)} repositories")

        synced_count = 0  # Track how many repos were actually synced

        # ------------------------------------------------------------------------
        # Step 4: Process each repository
        # ------------------------------------------------------------------------

        for repo in repos:
            # Extract repository metadata from GitHub API response
            repo_id = str(repo['id'])
            owner = repo['owner']['login']
            repo_name = repo['name']

            print(f"Processing repo: {repo_name}")

            # Check if repository already exists in our database
            existing_repo = db_client.get_repo(repo_id)

            # Fetch README file from GitHub
            readme_content = github_client.get_readme(owner, repo_name)

            if readme_content:
                # Calculate MD5 hash to detect if README has changed
                # This saves on AI API costs by only regenerating summaries when needed
                readme_hash = hashlib.md5(readme_content.encode()).hexdigest()

                # Skip if README hasn't changed since last sync
                if existing_repo and existing_repo.get('readme_hash') == readme_hash:
                    print(f"  Skipping {repo_name} - no changes detected")
                    continue

                # Generate AI summaries using Claude
                print(f"  Generating AI summaries for {repo_name}")
                high_level, detailed = generate_summaries(readme_content, ai_api_key)
            else:
                # Repository has no README file
                readme_hash = None
                high_level = "No README available"
                detailed = "This repository does not contain a README file."

            # ------------------------------------------------------------------------
            # Step 5: Prepare repository data for storage
            # ------------------------------------------------------------------------

            repo_data = {
                'repo_id': repo_id,                          # Primary key
                'name': repo_name,                           # Repository name
                'description': repo.get('description', ''),  # Short description
                'language': repo.get('language', 'Unknown'), # Primary language
                'stars': repo.get('stargazers_count', 0),    # Star count
                'forks': repo.get('forks_count', 0),         # Fork count
                'updated_at': repo['updated_at'],            # Last GitHub update
                'url': repo['html_url'],                     # GitHub URL
                'high_level_summary': high_level,            # AI-generated summary
                'detailed_summary': detailed,                # AI-generated detailed summary
                'last_synced': int(time.time()),             # Unix timestamp
                'readme_hash': readme_hash                   # MD5 hash for change detection
            }

            # Store repository data in DynamoDB
            db_client.put_repo(repo_data)
            synced_count += 1
            print(f"  Successfully synced {repo_name}")

        # ------------------------------------------------------------------------
        # Step 6: Update sync metadata
        # ------------------------------------------------------------------------
        # Record sync success and number of items synced for monitoring

        db_client.update_sync_metadata('github', 'success', synced_count)

        # Return success response
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully synced {synced_count} repositories'
            })
        }

    except Exception as e:
        # ------------------------------------------------------------------------
        # Error Handling
        # ------------------------------------------------------------------------
        # Log error and update sync metadata with failure status

        print(f"Error during GitHub sync: {str(e)}")

        # Update sync metadata to record failure
        # Note: We create a new db_client here in case the error occurred before initialization
        try:
            db_client = DBClient()
            db_client.update_sync_metadata('github', 'failed', 0, str(e))
        except Exception as meta_error:
            print(f"Failed to update sync metadata: {meta_error}")

        # Return error response
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
