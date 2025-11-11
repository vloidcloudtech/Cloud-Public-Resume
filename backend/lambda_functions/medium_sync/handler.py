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
