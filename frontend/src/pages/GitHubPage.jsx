import React, { useState, useEffect } from 'react';
import { getRepos, getRepo } from '../services/api';

function GitHubPage() {
  const [repos, setRepos] = useState([]);
  const [selectedRepo, setSelectedRepo] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchRepos();
  }, []);

  const fetchRepos = async () => {
    try {
      setLoading(true);
      const data = await getRepos();
      setRepos(data);
    } catch (error) {
      console.error('Error fetching repos:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleRepoClick = async (repoId) => {
    try {
      const data = await getRepo(repoId);
      setSelectedRepo(data);
    } catch (error) {
      console.error('Error fetching repo:', error);
    }
  };

  if (loading) {
    return <div className="loading"><div className="spinner"></div></div>;
  }

  if (selectedRepo) {
    return (
      <div className="fade-in">
        <button
          className="back-button"
          onClick={() => setSelectedRepo(null)}
        >
          ← Back to repositories
        </button>

        <div className="card">
          <div className="detail-header">
            <div>
              <h2 className="detail-title">{selectedRepo.name}</h2>
              <p className="repo-description">{selectedRepo.description}</p>
            </div>
            <span className="badge">{selectedRepo.language}</span>
          </div>

          <div className="detail-meta">
            <span>⭐ {selectedRepo.stars} stars</span>
            <span>🔀 {selectedRepo.forks} forks</span>
            <span>🕐 Updated {selectedRepo.updated_at}</span>
          </div>

          <div className="summary-box">
            <h3>
              💡 High-Level Summary
              <span className="ai-badge">AI Generated</span>
            </h3>
            <p className="summary-text">{selectedRepo.high_level_summary}</p>
          </div>

          <div className="summary-box">
            <h3>
              📄 Detailed Summary
              <span className="ai-badge">AI Generated</span>
            </h3>
            <p className="summary-text">{selectedRepo.detailed_summary}</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="fade-in">
      <div className="section-header">
        <h2>GitHub Repositories</h2>
        <p>Automatically synced with AI-generated summaries</p>
      </div>

      <div className="grid grid-2">
        {repos.map(repo => (
          <div
            key={repo.repo_id}
            className="card repo-card"
            onClick={() => handleRepoClick(repo.repo_id)}
          >
            <div className="repo-header">
              <div className="repo-title">
                💾 {repo.name}
              </div>
              <span className="badge">{repo.language}</span>
            </div>
            <p className="repo-description">{repo.description}</p>
            <div className="repo-summary">
              "{repo.high_level_summary}"
            </div>
            <div className="repo-stats">
              <span>⭐ {repo.stars}</span>
              <span>🔀 {repo.forks}</span>
              <span style={{ marginLeft: 'auto', color: '#8b5cf6' }}>
                View details →
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default GitHubPage;
