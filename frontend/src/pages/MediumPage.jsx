import React, { useState, useEffect } from 'react';
import { getPosts } from '../services/api';

function MediumPage() {
  const [posts, setPosts] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchPosts();
  }, []);

  const fetchPosts = async () => {
    try {
      setLoading(true);
      const data = await getPosts();
      setPosts(data);
    } catch (error) {
      console.error('Error fetching posts:', error);
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
        <h2>Medium Articles</h2>
        <p>Latest posts from my Medium blog</p>
      </div>

      <div className="grid grid-1">
        {posts.map(post => (
          <div key={post.post_id} className="card post-card">
            <div className="post-header">
              <h3 className="post-title">{post.title}</h3>
              <div className="post-meta">
                <span>📅 {new Date(post.published_date).toLocaleDateString()}</span>
                <span>⏱️ {post.read_time}</span>
                <span>👏 {post.claps} claps</span>
              </div>
            </div>
            <p className="post-excerpt">{post.excerpt}</p>
            <a
              href={post.url}
              target="_blank"
              rel="noopener noreferrer"
              className="card-link"
            >
              Read on Medium →
            </a>
          </div>
        ))}
      </div>
    </div>
  );
}

export default MediumPage;
