const express = require('express');
const multer = require('multer');
const jwt = require('jsonwebtoken');
const db = require('../config/database');
const router = express.Router();
const path = require('path');

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`);
  },
});
const upload = multer({ storage });

// Middleware to verify JWT
const authenticate = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) {
    console.error('No token provided');
    return res.status(401).json({ error: 'No token provided' });
  }
  jwt.verify(token, process.env.JWT_SECRET || 'secret_key', (err, decoded) => {
    if (err) {
      console.error('Invalid token:', err.message);
      return res.status(401).json({ error: 'Invalid token' });
    }
    req.userId = decoded.userId;
    next();
  });
};

// Create/Update Profile
router.post('/', authenticate, upload.single('pfp'), (req, res) => {
  const {
    first_name,
    last_name,
    nickname,
    age,
    gender,
    bio,
    region,
    city,
  } = req.body;
  const pfp_path = req.file ? req.file.path : null;

  if (!first_name || !last_name || !age || !region || !city) {
    console.error('Required fields missing:', { first_name, last_name, age, region, city });
    return res.status(400).json({ error: 'Required fields missing' });
  }

  db.run(
    `INSERT INTO profiles (user_id, first_name, last_name, nickname, age, gender, bio, region, city, pfp_path)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT(user_id) DO UPDATE SET
     first_name = excluded.first_name,
     last_name = excluded.last_name,
     nickname = excluded.nickname,
     age = excluded.age,
     gender = excluded.gender,
     bio = excluded.bio,
     region = excluded.region,
     city = excluded.city,
     pfp_path = excluded.pfp_path`,
    [
      req.userId,
      first_name,
      last_name,
      nickname || null,
      parseInt(age),
      gender || null,
      bio || null,
      region,
      city,
      pfp_path,
    ],
    (err) => {
      if (err) {
        console.error('Error saving profile:', err.message);
        return res.status(500).json({ error: 'Error saving profile' });
      }
      res.status(201).json({ message: 'Profile saved successfully' });
    }
  );
});

// Check if Profile Exists
router.get('/check', authenticate, (req, res) => {
  console.log('Checking profile for user_id:', req.userId);
  db.get(
    `SELECT id FROM profiles WHERE user_id = ?`,
    [req.userId],
    (err, row) => {
      if (err) {
        console.error('Error checking profile:', err.message);
        return res.status(500).json({ error: 'Error checking profile' });
      }
      console.log('Profile check result:', { userId: req.userId, hasProfile: !!row });
      res.json({ hasProfile: !!row });
    }
  );
});

// Get Current User's Profile with Notification Preference
router.get('/me', authenticate, (req, res) => {
  db.get(
    `SELECT p.*, u.email, u.name, u.notifications_enabled
     FROM profiles p
     JOIN users u ON p.user_id = u.id
     WHERE p.user_id = ?`,
    [req.userId],
    (err, row) => {
      if (err) {
        console.error('Error fetching profile:', err.message);
        return res.status(500).json({ error: 'Error fetching profile' });
      }
      if (!row) {
        return res.status(404).json({ error: 'Profile not found' });
      }
      res.json(row);
    }
  );
});

// Update Notification Preference
router.put('/notifications', authenticate, (req, res) => {
  const { notifications_enabled } = req.body;

  if (typeof notifications_enabled !== 'boolean') {
    return res.status(400).json({ error: 'Invalid notification preference' });
  }

  db.run(
    `UPDATE users SET notifications_enabled = ? WHERE id = ?`,
    [notifications_enabled ? 1 : 0, req.userId],
    function (err) {
      if (err) {
        console.error('Error updating notification preference:', err.message);
        return res.status(500).json({ error: 'Failed to update notification preference' });
      }
      if (this.changes === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      res.json({ message: 'Notification preference updated' });
    }
  );
});

module.exports = router;