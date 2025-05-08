const express = require('express');
const cors = require('cors');
const db = require('./config/database');

const app = express();
const port = 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Basic route to test the backend
app.get('/', (req, res) => {
  res.json({ message: 'Backend is working!' });
});

// Start Express server
app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});