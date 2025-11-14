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

    db_client = None  # Initialize to None so it's available in except block

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
        if db_client:
            db_client.update_sync_metadata('youtube', 'failed', 0, str(e))

        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
