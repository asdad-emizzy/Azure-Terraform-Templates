const express = require('express');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
const ENV = process.env.ENVIRONMENT || 'development';

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static('public'));

// Set view engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// Routes

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    environment: ENV
  });
});

// Home page
app.get('/', (req, res) => {
  res.render('index', {
    title: 'CMS Web Application',
    environment: ENV,
    version: '1.0.0'
  });
});

// Dashboard
app.get('/dashboard', (req, res) => {
  res.render('dashboard', {
    title: 'Dashboard',
    articles: mockArticles,
    stats: {
      totalArticles: mockArticles.length,
      totalUsers: 42,
      totalViews: 1250
    }
  });
});

// Articles API
app.get('/api/articles', (req, res) => {
  res.json({
    success: true,
    count: mockArticles.length,
    data: mockArticles
  });
});

app.get('/api/articles/:id', (req, res) => {
  const article = mockArticles.find(a => a.id === parseInt(req.params.id));
  
  if (!article) {
    return res.status(404).json({
      success: false,
      message: 'Article not found'
    });
  }
  
  res.json({
    success: true,
    data: article
  });
});

app.post('/api/articles', (req, res) => {
  const { title, content, author } = req.body;
  
  if (!title || !content || !author) {
    return res.status(400).json({
      success: false,
      message: 'Missing required fields: title, content, author'
    });
  }
  
  const newArticle = {
    id: mockArticles.length + 1,
    title,
    content,
    author,
    created_at: new Date().toISOString(),
    views: 0
  };
  
  mockArticles.push(newArticle);
  
  res.status(201).json({
    success: true,
    message: 'Article created',
    data: newArticle
  });
});

// About page
app.get('/about', (req, res) => {
  res.render('about', {
    title: 'About CMS'
  });
});

// Status page
app.get('/status', (req, res) => {
  res.json({
    application: 'CMS Web Application',
    version: '1.0.0',
    status: 'running',
    environment: ENV,
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    timestamp: new Date().toISOString()
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).render('404', {
    title: 'Page Not Found',
    path: req.path
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error',
    environment: ENV
  });
});

// Mock data
const mockArticles = [
  {
    id: 1,
    title: 'Welcome to Azure CMS',
    content: 'This is a sample article demonstrating a CMS application running on Azure Container Apps.',
    author: 'Admin',
    created_at: new Date(Date.now() - 86400000).toISOString(),
    views: 150
  },
  {
    id: 2,
    title: 'Terraform Infrastructure as Code',
    content: 'Learn how to define your Azure infrastructure using Terraform modules for reproducible deployments.',
    author: 'DevOps Team',
    created_at: new Date(Date.now() - 172800000).toISOString(),
    views: 320
  },
  {
    id: 3,
    title: 'Container Apps Best Practices',
    content: 'Best practices for deploying applications on Azure Container Apps including auto-scaling and monitoring.',
    author: 'Cloud Architect',
    created_at: new Date(Date.now() - 259200000).toISOString(),
    views: 245
  }
];

// Start server
const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`CMS Web Application Started`);
  console.log(`${'='.repeat(60)}`);
  console.log(`Port: ${PORT}`);
  console.log(`Environment: ${ENV}`);
  console.log(`Uptime: ${new Date().toISOString()}`);
  console.log(`${'='.repeat(60)}\n`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });
});

module.exports = app;
