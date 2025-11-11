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
