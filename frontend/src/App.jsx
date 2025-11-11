import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import HomePage from './pages/HomePage';
import GitHubPage from './pages/GitHubPage';
import MediumPage from './pages/MediumPage';
import YouTubePage from './pages/YouTubePage';

function App() {
  const [activeTab, setActiveTab] = useState('home');

  return (
    <Router>
      <div className="app">
        <nav className="navbar">
          <div className="nav-content">
            <div className="logo">
              💻 Your Portfolio
            </div>
            <div className="nav-tabs">
              <Link
                to="/"
                className={`nav-tab ${activeTab === 'home' ? 'active' : ''}`}
                onClick={() => setActiveTab('home')}
              >
                🏠 Home
              </Link>
              <Link
                to="/github"
                className={`nav-tab ${activeTab === 'github' ? 'active' : ''}`}
                onClick={() => setActiveTab('github')}
              >
                💾 GitHub
              </Link>
              <Link
                to="/medium"
                className={`nav-tab ${activeTab === 'medium' ? 'active' : ''}`}
                onClick={() => setActiveTab('medium')}
              >
                📝 Medium
              </Link>
              <Link
                to="/youtube"
                className={`nav-tab ${activeTab === 'youtube' ? 'active' : ''}`}
                onClick={() => setActiveTab('youtube')}
              >
                🎥 YouTube
              </Link>
            </div>
          </div>
        </nav>

        <main className="container">
          <Routes>
            <Route path="/" element={<HomePage />} />
            <Route path="/github" element={<GitHubPage />} />
            <Route path="/medium" element={<MediumPage />} />
            <Route path="/youtube" element={<YouTubePage />} />
          </Routes>
        </main>

        <footer className="footer">
          <div className="footer-content">
            <p>© 2024 Your Name. Auto-synced via AWS Lambda.</p>
            <div className="footer-links">
              <a href="https://github.com/yourusername">💾</a>
              <a href="https://linkedin.com/in/yourusername">💼</a>
              <a href="https://twitter.com/yourusername">🐦</a>
            </div>
          </div>
          <div className="sync-status">
            ✓ Last synced: {new Date().toLocaleString()}
          </div>
        </footer>
      </div>
    </Router>
  );
}

export default App;
