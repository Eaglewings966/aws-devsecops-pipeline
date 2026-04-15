'use strict';

const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// Health check endpoint
app.get('/', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    service: 'devops-demo-app',
    version: process.env.APP_VERSION || '2.0.0',
    environment: process.env.NODE_ENV || 'production',
    author: 'Emmanuel Ubani',
    timestamp: new Date().toISOString()
  });
});

// Readiness probe
app.get('/health', (req, res) => {
  res.status(200).json({ ready: true });
});

// Version endpoint
app.get('/version', (req, res) => {
  res.status(200).json({
    version: process.env.APP_VERSION || '2.0.0',
    commit: process.env.GIT_COMMIT || 'unknown'
  });
});

const server = app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = server;
