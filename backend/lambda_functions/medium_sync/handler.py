import json
import os
import time
import hashlib
import re
import sys
sys.path.append('/opt/python')

from db_client import DBClient
from api_clients import MediumClient

def strip_html(text):
    """Remove HTML tags from text"""
    if not text:
        return ""
    # Remove HTML tags
    clean = re.sub('<.*?>', '', text)
    # Replace multiple spaces with single space
    clean = re.sub(r'\s+', ' ', clean)
    # Trim whitespace
    return clean.strip()

def lambda_handler(event, context):
    """Main handler for Medium sync"""
    print("Starting Medium sync...")

    db_client = None  # Initialize to None so it's available in except block

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

            # Strip HTML from summary
            clean_summary = strip_html(post['summary'])
            excerpt = clean_summary[:300] + '...' if len(clean_summary) > 300 else clean_summary

            post_data = {
                'post_id': post_id,
                'title': post['title'],
                'excerpt': excerpt,
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
        if db_client:
            db_client.update_sync_metadata('medium', 'failed', 0, str(e))

        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
