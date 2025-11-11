import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json'
  }
});

export const getRepos = async () => {
  const response = await api.get('/api/repos');
  return response.data;
};

export const getRepo = async (id) => {
  const response = await api.get(`/api/repos/${id}`);
  return response.data;
};

export const getPosts = async () => {
  const response = await api.get('/api/posts');
  return response.data;
};

export const getVideos = async () => {
  const response = await api.get('/api/videos');
  return response.data;
};

export default api;
