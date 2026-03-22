import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../api/chat_api.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../session/user_session.dart';
import '../services/socket_service.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _loading = true;
  List<Chat> _chats = [];
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _setupSocketListeners();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  /// Setup Socket.IO listeners for realtime updates
  /// Task 10.4: Listen to messageStream for NEW_CHAT, MESSAGE, UPDATE_CHAT events
  /// Validates: Requirements 3.5, 3.6
  void _setupSocketListeners() {
    _socketSubscription = SocketService().messageStream.listen((data) {
      final type = data['type'] as String?;
      
      if (type == 'NEW_CHAT') {
        _handleNewChat(data);
      } else if (type == 'MESSAGE') {
        _handleMessage(data);
      } else if (type == 'UPDATE_CHAT') {
        _handleUpdateChat(data);
      }
    });
  }

  /// Handle NEW_CHAT event: insert new chat at top of list
  /// Validates: Requirement 3.6
  void _handleNewChat(Map<String, dynamic> data) {
    try {
      final chatData = data['chat'] as Map<String, dynamic>;
      final newChat = Chat.fromJson(chatData);
      
      if (!mounted) return;
      setState(() {
        _chats.insert(0, newChat);
      });
    } catch (e) {
      print('Error handling NEW_CHAT event: $e');
    }
  }

  /// Handle MESSAGE event: update chat's lastMessage and move to top
  /// Validates: Requirement 3.5
  void _handleMessage(Map<String, dynamic> data) {
    try {
      final messageData = data['message'] as Map<String, dynamic>;
      final message = Message.fromJson(messageData);
      final currentUserId = UserSession.instance.currentUser?.id;
      
      // Find the chat that this message belongs to
      final chatIndex = _chats.indexWhere((chat) =>
        (chat.user1.id == message.senderId && chat.user2.id == message.receiverId) ||
        (chat.user1.id == message.receiverId && chat.user2.id == message.senderId)
      );
      
      if (chatIndex >= 0) {
        if (!mounted) return;
        setState(() {
          // Create updated chat with new lastMessage
          final oldChat = _chats[chatIndex];
          final updatedChat = Chat(
            id: oldChat.id,
            user1: oldChat.user1,
            user2: oldChat.user2,
            status: 0, // Set to unread
            lastMessage: message,
          );
          
          // Remove from current position and insert at top
          _chats.removeAt(chatIndex);
          _chats.insert(0, updatedChat);
        });
      }
    } catch (e) {
      print('Error handling MESSAGE event: $e');
    }
  }

  /// Handle UPDATE_CHAT event: update chat status
  /// Validates: Requirement 6.4
  void _handleUpdateChat(Map<String, dynamic> data) {
    try {
      final chatData = data['chat'] as Map<String, dynamic>;
      final chatId = chatData['_id'] as String;
      final newStatus = chatData['status'] as int;
      
      // Find the chat and update its status
      final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
      
      if (chatIndex >= 0) {
        if (!mounted) return;
        setState(() {
          final oldChat = _chats[chatIndex];
          final updatedChat = Chat(
            id: oldChat.id,
            user1: oldChat.user1,
            user2: oldChat.user2,
            status: newStatus,
            lastMessage: oldChat.lastMessage,
          );
          
          _chats[chatIndex] = updatedChat;
        });
      }
    } catch (e) {
      print('Error handling UPDATE_CHAT event: $e');
    }
  }

  Future<void> _loadChats() async {
    setState(() {
      _loading = true;
    });
    
    try {
      final chats = await ChatApi.fetchChats();
      if (!mounted) return;
      setState(() {
        _chats = chats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      // Show error but don't block UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load chats: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Format timestamp for chat list display
  /// Examples: "2h ago", "Yesterday", "Jan 15"
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    // Less than 1 hour: show minutes
    if (difference.inMinutes < 60) {
      if (difference.inMinutes < 1) {
        return 'Just now';
      }
      return '${difference.inMinutes}m ago';
    }
    
    // Less than 24 hours: show hours
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    
    // Yesterday
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    
    // Less than 7 days: show day name
    if (difference.inDays < 7) {
      return DateFormat('EEEE').format(timestamp);
    }
    
    // Same year: show month and day
    if (timestamp.year == now.year) {
      return DateFormat('MMM d').format(timestamp);
    }
    
    // Different year: show full date
    return DateFormat('MMM d, yyyy').format(timestamp);
  }

  /// Navigate to ChatDetailScreen with selected chat
  /// Task 10.5: Validates Requirement 4.1
  void _navigateToChatDetail(Chat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(chat: chat),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: _loadChats,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (_chats.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SizedBox(height: 100),
          Center(
            child: Text(
              'No conversations yet',
              style: TextStyle(color: AppColors.goldMuted),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _chats.length,
      itemBuilder: (context, index) {
        final chat = _chats[index];
        final currentUserId = UserSession.instance.currentUser?.id;
        
        // Determine which user to display (the other user, not current user)
        final otherUser = chat.user1.id == currentUserId ? chat.user2 : chat.user1;
        
        // Get first letter of user's email for avatar
        final avatarLetter = otherUser.email.isNotEmpty 
            ? otherUser.email[0].toUpperCase() 
            : '?';
        
        // Format timestamp
        final timestampText = chat.lastMessage != null 
            ? _formatTimestamp(chat.lastMessage!.dateSent)
            : '';
        
        // Check if chat has unread messages (status = 0)
        final hasUnread = chat.status == 0;
        
        return Card(
          color: AppColors.surface,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: AppColors.gold,
              child: Text(
                avatarLetter,
                style: const TextStyle(
                  color: AppColors.onGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    otherUser.email,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (hasUnread)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            subtitle: chat.lastMessage != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        chat.lastMessage!.message,
                        style: const TextStyle(color: AppColors.goldMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timestampText,
                        style: const TextStyle(
                          color: AppColors.goldMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                : null,
            onTap: () => _navigateToChatDetail(chat),
          ),
        );
      },
    );
  }
}
