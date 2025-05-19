const express = require('express');
const jwt = require('jsonwebtoken');
const db = require('../config/database');
const router = express.Router();

// Middleware to verify JWT
const authenticate = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token provided' });
  jwt.verify(token, process.env.JWT_SECRET || 'secret_key', (err, decoded) => {
    if (err) return res.status(401).json({ error: 'Invalid token' });
    req.userId = decoded.userId;
    next();
  });
};

// Fetch Profiles with Filters
router.get('/', authenticate, (req, res) => {
  const { min_age, max_age, gender, region, city } = req.query;
  let query = `
    SELECT p.* FROM profiles p
    JOIN users u ON p.user_id = u.id
    WHERE p.user_id != ?`;
  const params = [req.userId];

  // Apply filters
  if (min_age) {
    query += ` AND p.age >= ?`;
    params.push(parseInt(min_age));
  }
  if (max_age) {
    query += ` AND p.age <= ?`;
    params.push(parseInt(max_age));
  }
  if (gender) {
    query += ` AND p.gender = ?`;
    params.push(gender);
  }
  if (region) {
    query += ` AND p.region = ?`;
    params.push(region);
  }
  if (city) {
    query += ` AND p.city = ?`;
    params.push(city);
  }

  // Exclude already swiped profiles
  query += `
    AND p.user_id NOT IN (
      SELECT target_user_id FROM swipes WHERE user_id = ?
    )`;
  params.push(req.userId);

  db.all(query, params, (err, rows) => {
    if (err) {
      console.error('Error fetching profiles:', err.message);
      return res.status(500).json({ error: 'Error fetching profiles' });
    }
    res.json({ profiles: rows });
  });
});

module.exports = router;