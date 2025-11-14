import requests
import base64

# Conditional imports - only needed for specific clients
try:
    import feedparser
except ImportError:
    # feedparser not installed - MediumClient won't work but other clients will
    feedparser = None

try:
    from googleapiclient.discovery import build
except ImportError:
    # Google API client not installed - YouTubeClient won't work but other clients will
    build = None

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
