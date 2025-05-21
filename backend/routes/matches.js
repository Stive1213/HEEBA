const express = require('express');
const router = express.Router();
const db = require('../config/database');

// Middleware to authenticate token
const authenticateToken = (req, res, next) => {
  const token = req.headers['authorization']?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Token required' });

  const jwt = require('jsonwebtoken');
  const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret';

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ error: 'Invalid token' });
    req.user = user;
    next();
  });
};

// GET /matches - Fetch matches for the authenticated user
router.get('/', authenticateToken, (req, res) => {
  const userId = req.user.userId; // Get userId from JWT token
  if (!userId) return res.status(400).json({ error: 'User ID not found in token' });

  db.all(
    `
    SELECT 
      CAST(m.id AS INTEGER) as match_id,
      CAST(COALESCE(p.user_id, 0) AS INTEGER) as user_id,
      COALESCE(p.first_name, 'Unknown') as first_name,
      COALESCE(p.last_name, 'User') as last_name,
      COALESCE(p.nickname, '') as nickname,
      COALESCE(p.age, 0) as age,
      COALESCE(p.gender, '') as gender,
      COALESCE(p.bio, '') as bio,
      COALESCE(p.region, 'Unknown') as region,
      COALESCE(p.city, 'Unknown') as city,
      p.pfp_path
    FROM matches m
    LEFT JOIN profiles p 
      ON p.user_id = CASE 
        WHEN m.user1_id = ? THEN m.user2_id 
        ELSE m.user1_id 
      END
    WHERE m.user1_id = ? OR m.user2_id = ?
    `,
    [userId, userId, userId],
    (err, rows) => {
      if (err) {
        console.error('Error fetching matches:', err.message);
        return res.status(500).json({ error: 'Failed to fetch matches' });
      }
      console.log('Fetched matches for user', userId, ':', rows);
      // Filter out invalid matches (e.g., where user_id or match_id is 0)
      const validRows = rows.filter(row => row.match_id !== 0 && row.user_id !== 0);
      if (validRows.length < rows.length) {
        console.log('Filtered out invalid matches:', rows.filter(row => row.match_id === 0 || row.user_id === 0));
      }
      res.json(validRows);
    }
  );
});

module.exports = router;