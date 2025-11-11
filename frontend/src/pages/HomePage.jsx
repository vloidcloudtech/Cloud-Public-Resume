import React from 'react';

function HomePage() {
  return (
    <div className="fade-in">
      <div className="hero">
        <h1 className="hero-title">Welcome to My Portfolio</h1>
        <p className="hero-subtitle">
          Automatically aggregated from GitHub, Medium, and YouTube
        </p>
      </div>

      <div className="grid grid-3">
        <div className="card">
          <div className="card-icon">💾</div>
          <h3>GitHub Projects</h3>
          <p>AI-powered summaries of my repositories and code contributions</p>
          <a href="/github" className="card-link">View Projects →</a>
        </div>

        <div className="card">
          <div className="card-icon">📝</div>
          <h3>Medium Articles</h3>
          <p>Latest technical articles and blog posts from Medium</p>
          <a href="/medium" className="card-link">Read Articles →</a>
        </div>

        <div className="card">
          <div className="card-icon">🎥</div>
          <h3>YouTube Videos</h3>
          <p>Educational content and tutorials from my channel</p>
          <a href="/youtube" className="card-link">Watch Videos →</a>
        </div>
      </div>

      <div className="stats-section">
        <h2>Auto-Synced Every 12 Hours</h2>
        <p>All content is automatically fetched and updated from external platforms</p>
      </div>
    </div>
  );
}

export default HomePage;
