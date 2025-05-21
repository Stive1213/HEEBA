const express = require('express');
const router = express.Router();
const db = require('../config/database');

// Middleware to authenticate token (imported logic)
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

// Fetch chat history for a match
router.get('/:matchId', authenticateToken, (req, res) => {
  const matchId = parseInt(req.params.matchId);
  if (isNaN(matchId)) {
    return res.status(400).json({ error: 'Invalid match ID' });
  }

  const userId = req.user.userId; // Changed from req.user.id to req.user.userId
  if (!userId) {
    return res.status(400).json({ error: 'User ID not found in token' });
  }

  // First, verify that the match involves the current user
  db.get(
    `
    SELECT user1_id, user2_id
    FROM matches
    WHERE id = ?
    `,
    [matchId],
    (err, match) => {
      if (err) {
        console.error('Error fetching match:', err.message);
        return res.status(500).json({ error: 'Failed to fetch match' });
      }
      if (!match) {
        return res.status(404).json({ error: 'Match not found' });
      }

      const { user1_id, user2_id } = match;
      if (userId !== user1_id && userId !== user2_id) {
        return res.status(403).json({ error: 'Unauthorized access to match' });
      }

      // Fetch messages for this match from the chats table
      const query = `
        SELECT 
          id,
          match_id,
          sender_id,
          CASE 
            WHEN sender_id = ? THEN ?
            ELSE ?
          END as receiver_id,
          message as content,
          created_at
        FROM chats
        WHERE match_id = ?
        ORDER BY created_at ASC
      `;

      db.all(query, [userId, user2_id, user1_id, matchId], (err, messages) => {
        if (err) {
          console.error('Error fetching messages:', err.message);
          return res.status(500).json({ error: 'Failed to fetch messages' });
        }
        console.log('Fetched messages for match', matchId, ':', messages);
        res.json({ messages });
      });
    }
  );
});

module.exports = router;