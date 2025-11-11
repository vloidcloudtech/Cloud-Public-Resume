import React, { useState, useEffect } from 'react';
import { getVideos } from '../services/api';

function YouTubePage() {
  const [videos, setVideos] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchVideos();
  }, []);

  const fetchVideos = async () => {
    try {
      setLoading(true);
      const data = await getVideos();
      setVideos(data);
    } catch (error) {
      console.error('Error fetching videos:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="loading"><div className="spinner"></div></div>;
  }

  return (
    <div className="fade-in">
      <div className="section-header">
        <h2>YouTube Videos</h2>
        <p>Latest videos from my channel</p>
      </div>

      <div className="grid grid-3">
        {videos.map(video => (
          <div key={video.video_id} className="card video-card">
            <div className="video-thumbnail">
              <img src={video.thumbnail_url} alt={video.title} />
              <div className="video-duration">{video.duration}</div>
            </div>
            <div className="video-content">
              <h3 className="video-title">{video.title}</h3>
              <p className="video-description">{video.description}</p>
              <div className="video-meta">
                <span>👁️ {video.views} views</span>
                <span>📅 {video.published_date}</span>
              </div>
              <a
                href={video.url}
                target="_blank"
                rel="noopener noreferrer"
                className="card-link"
              >
                Watch on YouTube →
              </a>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default YouTubePage;
