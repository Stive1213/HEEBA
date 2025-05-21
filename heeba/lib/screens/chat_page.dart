import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart'; // Use web_socket_channel for web
import '../models/message.dart';
import '../services/api_service.dart';

class ChatPage extends StatefulWidget {
  final int matchId;
  final String matchName;

  const ChatPage({super.key, required this.matchId, required this.matchName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  List<Message> _messages = [];
  WebSocketChannel? _channel; // Make nullable to handle initialization failure
  bool _isLoading = false;
  late int _currentUserId;
  bool _notificationsEnabled = true; // Default to true

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);

    // Fetch current user ID and notification preference
    try {
      final currentProfile = await Provider.of<ApiService>(context, listen: false).getCurrentProfile();
      _currentUserId = currentProfile.userId;
      _notificationsEnabled = currentProfile.notificationsEnabled; // Load notification preference
      print('Current user ID: $_currentUserId');
      print('Notifications enabled: $_notificationsEnabled');
    } catch (e) {
      print('Error fetching current user profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user profile: ${e.toString().replaceAll('Exception: ', '')}')),
      );
      setState(() => _isLoading = false);
      return;
    }

    // Fetch chat history
    try {
      print('Fetching chat history for matchId: ${widget.matchId}');
      final messages = await Provider.of<ApiService>(context, listen: false).fetchChatHistory(widget.matchId);
      setState(() {
        _messages = messages;
      });
      print('Chat history loaded: ${messages.length} messages');
    } catch (e) {
      print('Error fetching chat history: $e');
      if (_notificationsEnabled) { // Only show if notifications are enabled
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chat history: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    }

    // Connect to WebSocket
    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:3000'));
      _channel!.stream.listen(
        (data) {
          final messageData = jsonDecode(data);
          if (messageData['error'] != null) {
            if (_notificationsEnabled) { // Only show if notifications are enabled
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${messageData['error']}')),
              );
            }
            return;
          }

          final message = Message(
            id: 0, // ID not needed for display
            senderId: messageData['sender_id'],
            receiverId: messageData['receiver_id'],
            content: messageData['content'],
            createdAt: messageData['created_at'],
          );

          // Only add message if it pertains to this chat
          if ((message.senderId == _currentUserId && message.receiverId == widget.matchId) ||
              (message.senderId == widget.matchId && message.receiverId == _currentUserId)) {
            setState(() {
              _messages.add(message);
            });
            // Show notification if enabled and message is from the other user
            if (_notificationsEnabled && message.senderId == widget.matchId) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('New message from ${widget.matchName}')),
              );
            }
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          if (_notificationsEnabled) { // Only show if notifications are enabled
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('WebSocket connection error')),
            );
          }
        },
        onDone: () {
          print('WebSocket connection closed');
          if (_notificationsEnabled) { // Only show if notifications are enabled
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('WebSocket connection closed')),
            );
          }
        },
      );
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      if (_notificationsEnabled) { // Only show if notifications are enabled
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect to WebSocket: ${e.toString()}')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    if (_channel == null) {
      if (_notificationsEnabled) { // Only show if notifications are enabled
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot send message: WebSocket not connected')),
        );
      }
      return;
    }

    final message = {
      'senderId': _currentUserId,
      'receiverId': widget.matchId,
      'content': _messageController.text.trim(),
    };

    try {
      _channel!.sink.add(jsonEncode(message));
      _messageController.clear();
    } catch (e) {
      print('Error sending message: $e');
      if (_notificationsEnabled) { // Only show if notifications are enabled
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _channel?.sink.close(); // Safely close if _channel is not null
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.matchName}', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEC407A), Color(0xFFF06292)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEC407A)))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.senderId == _currentUserId;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: isMe
                                ? const LinearGradient(
                                    colors: [Color(0xFFEC407A), Color(0xFFF06292)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isMe ? null : const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.content,
                                style: TextStyle(
                                  color: isMe ? Colors.white : const Color(0xFF1B263B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message.createdAt.substring(11, 16), // Show time (HH:MM)
                                style: const TextStyle(fontSize: 10, color: Color(0x666666)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: Color(0x666666)),
                            filled: true,
                            fillColor: Color(0xFFFFFFFF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: Color(0x666666)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: Color(0x666666)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: Color(0xFFEC407A), width: 2),
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFEC407A), Color(0xFFEF9A9A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send, color: Colors.white),
                        ),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}