import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../session/user_session.dart';
import '../api/message_api.dart';
import 'package:intl/intl.dart';

/// ChatDetailScreen - displays messages in a conversation
/// Task 11.1: Implemented StatefulWidget with chat parameter, AppBar with back button and other user's name
/// Task 11.2: Implemented message loading and display with ListView
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

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final messages = await MessageApi.fetchMessages(widget.chat.id);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
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
      body: _buildBody(currentUserId),
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
            Text(
              'Error loading messages',
              style: const TextStyle(
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
          'No messages yet',
          style: TextStyle(
            color: AppColors.goldMuted,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: isMe ? AppColors.background : AppColors.gold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, h:mm a').format(message.dateSent),
              style: TextStyle(
                color: isMe ? AppColors.background.withOpacity(0.7) : AppColors.goldMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
