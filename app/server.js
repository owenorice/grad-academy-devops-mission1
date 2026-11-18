'use strict';

// Mock Rockstar "Social Hub" API — a tiny web app you deploy to Azure with
// Terraform in Mission 1. It's just one Node.js process inside one Docker
// container. Nothing fancy: a few endpoints that return JSON.

const express = require('express');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 80;
const HOSTNAME = os.hostname();

app.use(express.json());

// Health check — handy for confirming the app is alive.
app.get('/api/v1/health', (req, res) => {
  res.json({ status: 'ok', host: HOSTNAME });
});

// A tiny, fixed player profile.
app.get('/api/v1/profile', (req, res) => {
  res.json({
    id: req.query.id || '00000000',
    handle: 'LuciaCaminos',
    city: 'Vice City',
    level: 6,
    host: HOSTNAME,
  });
});

// Landing page.
app.get('/', (req, res) => {
  res.json({ service: 'rockstar-social-hub', host: HOSTNAME });
});

app.listen(PORT, () => {
  console.log(`Social Hub listening on :${PORT} (host ${HOSTNAME})`);
});
