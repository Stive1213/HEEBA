const express = require('express');
const cors = require('cors');
const db = require('./config/database');
const authRouter = require('./routes/auth');

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

// Basic route to test the backend
app.get('/', (req, res) => {
  res.json({ message: 'Backend is working!' });
});

// Auth routes
app.use('/auth', authRouter);

// Start Express server
app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});