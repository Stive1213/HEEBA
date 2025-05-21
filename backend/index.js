const express = require('express');
const cors = require('cors');
const authRouter = require('./routes/auth');
const profilesRouter = require('./routes/profiles');
const profileRouter = require('./routes/profile');
const swipeRouter = require('./routes/swipe');
const matchesRouter = require('./routes/matches');
const messagesRouter = require('./routes/messages');
const fs = require('fs');
const { WebSocketServer } = require('ws');
const db = require('./config/database');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

// Create uploads directory if it doesn't exist
const uploadsDir = 'uploads';
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir);
}

// Middleware
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads')); // Serve uploads directory

// Routes
app.use('/auth', authRouter);
app.use('/profiles', profilesRouter);
app.use('/profile', profileRouter);
app.use('/swipe', swipeRouter);
app.use('/matches', matchesRouter);
app.use('/messages', messagesRouter);
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to the Dating App API!' });
});

// Start Express server
const server = app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});

// WebSocket server for real-time chat
const wss = new WebSocketServer({ server });

wss.on('connection', (ws) => {
  console.log('New WebSocket connection');

  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message.toString());
      const { senderId, receiverId, content } = data;

      if (!senderId || !receiverId || !content) {
        ws.send(JSON.stringify({ error: 'Invalid message format' }));
        return;
      }

      // receiverId is actually the matchId in this context
      const matchId = receiverId;

      // Look up the match to determine the other user (actual receiver)
      db.get(
        `
        SELECT user1_id, user2_id
        FROM matches
        WHERE id = ?
        `,
        [matchId],
        (err, match) => {
          if (err) {
            console.error('Error finding match:', err.message);
            ws.send(JSON.stringify({ error: 'Failed to find match' }));
            return;
          }
          if (!match) {
            ws.send(JSON.stringify({ error: 'Match not found' }));
            return;
          }

          const { user1_id, user2_id } = match;
          const actualReceiverId = senderId === user1_id ? user2_id : user1_id;

          if (!actualReceiverId) {
            ws.send(JSON.stringify({ error: 'Invalid match participants' }));
            return;
          }

          const createdAt = new Date().toISOString();

          // Save message to the chats table
          db.run(
            `
            INSERT INTO chats (match_id, sender_id, message, created_at)
            VALUES (?, ?, ?, ?)
            `,
            [matchId, senderId, content, createdAt],
            (err) => {
              if (err) {
                console.error('Error saving message:', err.message);
                ws.send(JSON.stringify({ error: 'Failed to save message' }));
                return;
              }

              // Broadcast message to both sender and receiver
              const messageData = {
                sender_id: senderId,
                receiver_id: actualReceiverId,
                content,
                created_at: createdAt,
              };

              wss.clients.forEach((client) => {
                if (client.readyState === 1) {
                  client.send(JSON.stringify(messageData));
                }
              });
            }
          );
        }
      );
    } catch (err) {
      console.error('Error processing WebSocket message:', err.message);
      ws.send(JSON.stringify({ error: 'Invalid message format' }));
    }
  });

  ws.on('close', () => {
    console.log('WebSocket connection closed');
  });

  ws.on('error', (error) => {
    console.error('WebSocket error:', error.message);
  });
});