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
