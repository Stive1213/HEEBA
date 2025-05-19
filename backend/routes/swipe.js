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

// Record Swipe
router.post('/', authenticate, (req, res) => {
  const { target_user_id, swipe_type } = req.body;

  if (!target_user_id || !['right', 'left'].includes(swipe_type)) {
    return res.status(400).json({ error: 'Invalid swipe data' });
  }

  const now = new Date().toISOString();

  // Insert the swipe
  db.run(
    `INSERT INTO swipes (user_id, target_user_id, swipe_type, created_at)
     VALUES (?, ?, ?, ?)`,
    [req.userId, target_user_id, swipe_type, now],
    function (err) {
      if (err) {
        console.error('Error recording swipe:', err.message);
        if (err.message.includes('UNIQUE constraint')) {
          return res.status(400).json({ error: 'Already swiped this user' });
        }
        return res.status(500).json({ error: 'Error recording swipe' });
      }

      console.log(`Swipe recorded: ${req.userId} -> ${target_user_id} [${swipe_type}]`);

      // If it's a right swipe, check for mutual swipe
      if (swipe_type === 'right') {
        db.get(
          `SELECT * FROM swipes 
           WHERE user_id = ? AND target_user_id = ? AND swipe_type = 'right'`,
          [target_user_id, req.userId],
          (err, mutualSwipe) => {
            if (err) {
              console.error('Error checking mutual swipe:', err.message);
              return res.status(500).json({ error: 'Swipe recorded, but error checking for match' });
            }

            if (mutualSwipe) {
              // Create match with sorted user IDs to respect UNIQUE and CHECK constraints
              const [user1_id, user2_id] =
                req.userId < target_user_id
                  ? [req.userId, target_user_id]
                  : [target_user_id, req.userId];

              db.run(
                `INSERT OR IGNORE INTO matches (user1_id, user2_id, created_at)
                 VALUES (?, ?, ?)`,
                [user1_id, user2_id, now],
                function (err) {
                  if (err) {
                    console.error('Error inserting match:', err.message);
                    return res.status(500).json({ error: 'Swipe recorded, but error saving match' });
                  }

                  console.log(`💘 It's a match! ${user1_id} <--> ${user2_id}`);
                  return res.status(201).json({ message: 'Swipe recorded and match created!' });
                }
              );
            } else {
              // No mutual swipe yet
              res.status(201).json({ message: 'Swipe recorded' });
            }
          }
        );
      } else {
        // Left swipe - no need to check for match
        res.status(201).json({ message: 'Swipe recorded' });
      }
    }
  );
});

module.exports = router;
