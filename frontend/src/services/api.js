import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com';

console.log('[API] Using API Base URL:', API_BASE_URL);
console.log('[API] VITE_API_URL env var:', import.meta.env.VITE_API_URL);

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json'
  }
});

export const getRepos = async () => {
  console.log('[API] Fetching repos from:', `${API_BASE_URL}/api/repos`);
  try {
    const response = await api.get('/api/repos');
    console.log('[API] Repos response:', response.data);
    return response.data;
  } catch (error) {
    console.error('[API] Error fetching repos:', error);
    throw error;
  }
};

export const getRepo = async (id) => {
  const response = await api.get(`/api/repos/${id}`);
  return response.data;
};

export const getPosts = async () => {
  console.log('[API] Fetching posts from:', `${API_BASE_URL}/api/posts`);
  try {
    const response = await api.get('/api/posts');
    console.log('[API] Posts response:', response.data);
    return response.data;
  } catch (error) {
    console.error('[API] Error fetching posts:', error);
    throw error;
  }
};

export const getVideos = async () => {
  console.log('[API] Fetching videos from:', `${API_BASE_URL}/api/videos`);
  try {
    const response = await api.get('/api/videos');
    console.log('[API] Videos response:', response.data);
    return response.data;
  } catch (error) {
    console.error('[API] Error fetching videos:', error);
    throw error;
  }
};

export default api;
