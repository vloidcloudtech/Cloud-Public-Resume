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
              VloidCloudTech
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
            <p>© 2024 VloidCloudTech. Auto-synced via AWS Lambda.</p>
            <div className="footer-links">
              <a href="https://github.com/vloidcloudtech" target="_blank" rel="noopener noreferrer" aria-label="GitHub">
                <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                  <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                </svg>
              </a>
              <a href="https://www.linkedin.com/in/jaden-walker306" target="_blank" rel="noopener noreferrer" aria-label="LinkedIn">
                <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                  <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>
                </svg>
              </a>
              <a href="https://medium.com/@vloidcloudtech" target="_blank" rel="noopener noreferrer" aria-label="Medium">
                <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                  <path d="M13.54 12a6.8 6.8 0 01-6.77 6.82A6.8 6.8 0 010 12a6.8 6.8 0 016.77-6.82A6.8 6.8 0 0113.54 12zM20.96 12c0 3.54-1.51 6.42-3.38 6.42-1.87 0-3.39-2.88-3.39-6.42s1.52-6.42 3.39-6.42 3.38 2.88 3.38 6.42M24 12c0 3.17-.53 5.75-1.19 5.75-.66 0-1.19-2.58-1.19-5.75s.53-5.75 1.19-5.75C23.47 6.25 24 8.83 24 12z"/>
                </svg>
              </a>
              <a href="https://www.youtube.com/@JayTechLife" target="_blank" rel="noopener noreferrer" aria-label="YouTube">
                <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                  <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/>
                </svg>
              </a>
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
