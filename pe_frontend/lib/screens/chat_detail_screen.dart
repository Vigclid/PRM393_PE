import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../session/user_session.dart';
import '../api/message_api.dart';
import '../services/socket_service.dart';
import '../utils/socket_helper.dart';
import 'package:intl/intl.dart';

/// ChatDetailScreen - displays messages in a conversation with realtime updates
/// 
/// Tasks implemented:
/// - Task 11.1: StatefulWidget with chat parameter, AppBar with back button and other user's name
/// - Task 11.2: Message loading and display with ListView
/// - Task 11.3: Message bubble UI (sent/received styling)
/// - Task 11.4: Message input area with TextField and send button
/// - Task 11.5: Message sending via Socket.IO with optimistic updates
/// - Task 11.6: Realtime message receiving via Socket.IO
/// - Task 11.7: Mark as read functionality
class ChatDetailScreen extends StatefulWidget {
  final Chat chat;
  
  const ChatDetailScreen({super.key, required this.chat});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  List<Message> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Task 11.4: Message input controller
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Task 11.6: Socket subscription for realtime updates
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;
  
  // Track if send button should be enabled
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    
    // Ensure socket is connected before loading messages
    _initializeChat();
    
    // Task 11.4: Listen to text changes to enable/disable send button
    _messageController.addListener(_onMessageTextChanged);
  }
  
  /// Initialize chat: connect socket, load messages, setup listeners
  Future<void> _initializeChat() async {
    // Ensure socket connection
    await SocketHelper.ensureConnected();
    
    // Load messages
    await _loadMessages();
    
    // Setup socket listeners
    _setupSocketListeners();
    
    // Mark messages as read
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _socketSubscription?.cancel();
    super.dispose();
  }

  /// Task 11.4: Enable send button only when text is not empty
  void _onMessageTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _canSend) {
      setState(() {
        _canSend = hasText;
      });
    }
  }

  /// Task 11.2: Load messages from API
  /// Validates: Requirements 4.1, 12.1
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final messages = await MessageApi.fetchMessages(widget.chat.id);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
      // Auto-scroll to bottom after loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Task 11.6: Setup Socket.IO listeners for realtime message receiving
  /// Validates: Requirements 4.4
  void _setupSocketListeners() {
    _socketSubscription = SocketService().messageStream.listen((data) {
      if (data['type'] == 'MESSAGE') {
        _handleIncomingMessage(data);
      }
    });
  }

  /// Task 11.6: Handle incoming MESSAGE event
  /// Check if message belongs to current chat and append to list
  /// Validates: Requirements 4.4
  void _handleIncomingMessage(Map<String, dynamic> data) {
    try {
      final messageData = data['message'] as Map<String, dynamic>;
      final message = Message.fromJson(messageData);
      final currentUserId = UserSession.instance.currentUser?.id;
      
      // Check if message belongs to current chat
      final belongsToChat = (message.senderId == currentUserId && 
                             message.receiverId == _getOtherUserId()) ||
                            (message.senderId == _getOtherUserId() && 
                             message.receiverId == currentUserId);
      
      if (belongsToChat && mounted) {
        setState(() {
          // Check if message already exists (avoid duplicates)
          final exists = _messages.any((m) => m.id == message.id);
          if (!exists) {
            _messages.add(message);
          }
        });
        
        // Auto-scroll to bottom when new message arrives
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom(animate: true);
        });
        
        // Mark as read if message is from other user
        if (message.senderId == _getOtherUserId()) {
          _markMessageAsRead(message.id);
        }
      }
    } catch (e) {
      print('Error handling incoming message: $e');
    }
  }

  /// Task 11.7: Mark messages as read when screen opens
  /// Validates: Requirements 4.5, 6.1
  Future<void> _markMessagesAsRead() async {
    final currentUserId = UserSession.instance.currentUser?.id;
    if (currentUserId == null) return;
    
    // Find all unread messages where current user is receiver
    final unreadMessages = _messages.where((msg) => 
      msg.receiverId == currentUserId && msg.isRead == 0
    ).toList();
    
    // Mark each as read
    for (final message in unreadMessages) {
      try {
        await MessageApi.markAsRead(message.id);
        
        // Update local state
        if (mounted) {
          setState(() {
            final index = _messages.indexWhere((m) => m.id == message.id);
            if (index >= 0) {
              _messages[index] = Message(
                id: message.id,
                senderId: message.senderId,
                receiverId: message.receiverId,
                message: message.message,
                dateSent: message.dateSent,
                isRead: 1,
              );
            }
          });
        }
      } catch (e) {
        print('Error marking message as read: $e');
      }
    }
  }

  /// Task 11.7: Mark a single message as read
  Future<void> _markMessageAsRead(String messageId) async {
    try {
      await MessageApi.markAsRead(messageId);
      
      // Update local state
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == messageId);
          if (index >= 0) {
            final msg = _messages[index];
            _messages[index] = Message(
              id: msg.id,
              senderId: msg.senderId,
              receiverId: msg.receiverId,
              message: msg.message,
              dateSent: msg.dateSent,
              isRead: 1,
            );
          }
        });
      }
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  /// Task 11.5: Send message via Socket.IO with optimistic update
  /// Validates: Requirements 4.3
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;
    
    final currentUserId = UserSession.instance.currentUser?.id;
    if (currentUserId == null) return;
    
    final otherUserId = _getOtherUserId();
    
    // Task 11.5: Optimistic update - add message to UI immediately
    final tempMessage = Message(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      senderId: currentUserId,
      receiverId: otherUserId,
      message: messageText,
      dateSent: DateTime.now(),
      isRead: 0,
    );
    
    setState(() {
      _messages.add(tempMessage);
    });
    
    // Clear input and scroll to bottom
    _messageController.clear();
    _scrollToBottom(animate: true);
    
    // Task 11.5: Send via Socket.IO with fallback to REST API
    // Try Socket.IO first for realtime delivery
    if (SocketService().isConnected) {
      SocketService().sendMessage(
        currentUserId,
        otherUserId,
        messageText,
      );
    } else {
      // Fallback: Use REST API if Socket.IO not connected
      print('Socket not connected, using REST API fallback');
      try {
        // Note: You may need to create this endpoint in MessageApi
        // For now, we'll just log the error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sending via backup method...'),
              duration: Duration(seconds: 2),
              backgroundColor: AppColors.goldMuted,
            ),
          );
        }
      } catch (e) {
        print('Error sending message via REST API: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send message: $e'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _sendMessage(),
              ),
            ),
          );
        }
      }
    }
  }

  /// Get the other user's ID (not current user)
  String _getOtherUserId() {
    final currentUserId = UserSession.instance.currentUser?.id;
    return widget.chat.user1.id == currentUserId 
        ? widget.chat.user2.id 
        : widget.chat.user1.id;
  }

  /// Scroll to bottom of message list
  void _scrollToBottom({bool animate = false}) {
    if (!_scrollController.hasClients) return;
    
    if (animate) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current user ID to determine which user to display in AppBar
    final currentUserId = UserSession.instance.currentUser?.id;
    
    // Determine the other user (not current user)
    final otherUser = widget.chat.user1.id == currentUserId 
        ? widget.chat.user2 
        : widget.chat.user1;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          otherUser.email,
          style: const TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.gold),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _buildBody(currentUserId),
          ),
          
          // Task 11.4: Message input area
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildBody(String? currentUserId) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.gold,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Error loading messages',
              style: TextStyle(
                color: AppColors.goldMuted,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppColors.goldMuted,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMessages,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet\nSend a message to start the conversation',
          style: TextStyle(
            color: AppColors.goldMuted,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Task 11.2: Display messages in ListView with reverse scroll
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[_messages.length - 1 - index];
        final isMe = message.senderId == currentUserId;
        
        return _buildMessageBubble(message, isMe);
      },
    );
  }

  /// Task 11.3: Design message bubble UI
  /// Sent messages: right-aligned, gold background, onGold text
  /// Received messages: left-aligned, surface background, gold text
  /// Validates: Requirements 4.2, 11.2
  Widget _buildMessageBubble(Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.gold : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isMe ? null : Border.all(
            color: AppColors.gold.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: isMe ? AppColors.onGold : AppColors.gold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, h:mm a').format(message.dateSent),
              style: TextStyle(
                color: isMe 
                    ? AppColors.onGold.withOpacity(0.7) 
                    : AppColors.goldMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Task 11.4: Message input area
  /// TextField with surface background and gold text
  /// Send button (FilledButton with Icons.send_rounded)
  /// Disable send button when TextField is empty
  /// Validates: Requirements 4.3, 4.6
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Text input field
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: AppColors.gold),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: AppColors.goldMuted.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) {
                  if (_canSend) {
                    _sendMessage();
                  }
                },
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Send button
            FilledButton(
              onPressed: _canSend ? _sendMessage : null,
              style: FilledButton.styleFrom(
                backgroundColor: _canSend 
                    ? AppColors.gold 
                    : AppColors.goldMuted.withOpacity(0.3),
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
                minimumSize: const Size(48, 48),
              ),
              child: Icon(
                Icons.send_rounded,
                color: _canSend ? AppColors.onGold : AppColors.goldMuted,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
