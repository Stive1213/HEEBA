const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/database');
const router = express.Router();

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

// Sign Up
router.post('/signup', (req, res) => {
  const { name, email, password } = req.body;
  if (!name || !email || !password) {
    return res.status(400).json({ error: 'All fields are required' });
  }
  // Hash password
  bcrypt.hash(password, 10, (err, hashedPassword) => {
    if (err) {
      return res.status(500).json({ error: 'Error hashing password' });
    }
    // Insert user
    db.run(
      `INSERT INTO users (name, email, password) VALUES (?, ?, ?)`,
      [name, email, hashedPassword],
      function (err) {
        if (err) {
          return res.status(400).json({ error: 'Email already exists' });
        }
        // Generate JWT
        const token = jwt.sign({ userId: this.lastID }, process.env.JWT_SECRET || 'secret_key', {
          expiresIn: '1h',
        });
        res.status(201).json({ token, user: { id: this.lastID, name, email } });
      }
    );
  });
});

// Login
router.post('/login', (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }
  // Find user
  db.get(`SELECT * FROM users WHERE email = ?`, [email], (err, user) => {
    if (err || !user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    // Compare password
    bcrypt.compare(password, user.password, (err, isMatch) => {
      if (err || !isMatch) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }
      // Generate JWT
      const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET || 'secret_key', {
        expiresIn: '1h',
      });
      res.json({ token, user: { id: user.id, name: user.name, email: user.email } });
    });
  });
});

// Change Password
router.put('/change-password', authenticate, (req, res) => {
  const { currentPassword, newPassword } = req.body;

  if (!currentPassword || !newPassword) {
    return res.status(400).json({ error: 'Current and new password are required' });
  }

  if (newPassword.length < 6) {
    return res.status(400).json({ error: 'New password must be at least 6 characters' });
  }

  db.get(`SELECT password FROM users WHERE id = ?`, [req.userId], (err, user) => {
    if (err) {
      console.error('Error fetching user:', err.message);
      return res.status(500).json({ error: 'Database error' });
    }
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    bcrypt.compare(currentPassword, user.password, (err, isMatch) => {
      if (err || !isMatch) {
        return res.status(401).json({ error: 'Current password is incorrect' });
      }

      bcrypt.hash(newPassword, 10, (err, hashedNewPassword) => {
        if (err) {
          return res.status(500).json({ error: 'Error hashing new password' });
        }

        db.run(
          `UPDATE users SET password = ? WHERE id = ?`,
          [hashedNewPassword, req.userId],
          function (err) {
            if (err) {
              console.error('Error updating password:', err.message);
              return res.status(500).json({ error: 'Failed to update password' });
            }
            if (this.changes === 0) {
              return res.status(404).json({ error: 'User not found' });
            }
            res.json({ message: 'Password updated successfully' });
          }
        );
      });
    });
  });
});

// Delete Account
router.delete('/delete-account', authenticate, (req, res) => {
  // Start a transaction to delete user-related data
  db.serialize(() => {
    // Delete chats associated with matches involving the user
    db.run(
      `DELETE FROM chats
       WHERE match_id IN (
         SELECT id FROM matches WHERE user1_id = ? OR user2_id = ?
       )`,
      [req.userId, req.userId],
      (err) => {
        if (err) {
          console.error('Error deleting chats:', err.message);
          return res.status(500).json({ error: 'Failed to delete chats' });
        }
      }
    );

    // Delete matches involving the user
    db.run(
      `DELETE FROM matches WHERE user1_id = ? OR user2_id = ?`,
      [req.userId, req.userId],
      (err) => {
        if (err) {
          console.error('Error deleting matches:', err.message);
          return res.status(500).json({ error: 'Failed to delete matches' });
        }
      }
    );

    // Delete swipes involving the user
    db.run(
      `DELETE FROM swipes WHERE user_id = ? OR target_user_id = ?`,
      [req.userId, req.userId],
      (err) => {
        if (err) {
          console.error('Error deleting swipes:', err.message);
          return res.status(500).json({ error: 'Failed to delete swipes' });
        }
      }
    );

    // Delete the user's profile
    db.run(
      `DELETE FROM profiles WHERE user_id = ?`,
      [req.userId],
      (err) => {
        if (err) {
          console.error('Error deleting profile:', err.message);
          return res.status(500).json({ error: 'Failed to delete profile' });
        }
      }
    );

    // Delete the user
    db.run(
      `DELETE FROM users WHERE id = ?`,
      [req.userId],
      function (err) {
        if (err) {
          console.error('Error deleting user:', err.message);
          return res.status(500).json({ error: 'Failed to delete user' });
        }
        if (this.changes === 0) {
          return res.status(404).json({ error: 'User not found' });
        }
        res.json({ message: 'Account deleted successfully' });
      }
    );
  });
});

module.exports = router;