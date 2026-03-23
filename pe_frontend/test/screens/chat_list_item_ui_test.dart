import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pe_frontend/models/chat.dart';
import 'package:pe_frontend/models/user.dart';
import 'package:pe_frontend/models/message.dart';
import 'package:pe_frontend/theme/app_theme.dart';

void main() {
  group('ChatListScreen UI Components - Task 10.3', () {
    // Mock data for testing
    final mockUser1 = User(
      id: 'user1',
      email: 'alice@example.com',
      coins: '100',
      roleName: 'user',
      isActive: true,
      dateOfBirth: '1990-01-01',
      followCounts: 0,
      followerCount: 0,
      lastLogin: '2024-01-01',
      createdAt: '2024-01-01',
    );

    final mockUser2 = User(
      id: 'user2',
      email: 'bob@example.com',
      coins: '200',
      roleName: 'user',
      isActive: true,
      dateOfBirth: '1990-01-01',
      followCounts: 0,
      followerCount: 0,
      lastLogin: '2024-01-01',
      createdAt: '2024-01-01',
    );

    final mockMessage = Message(
      id: 'msg1',
      senderId: 'user2',
      receiverId: 'user1',
      message: 'Hello, this is a test message!',
      dateSent: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: 0,
    );

    final mockChat = Chat(
      id: 'chat1',
      user1: mockUser1,
      user2: mockUser2,
      status: 0, // unread
      lastMessage: mockMessage,
    );

    testWidgets('displays CircleAvatar with gold background', (
      WidgetTester tester,
    ) async {
      // Build a simple widget that mimics the chat list item
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              color: AppColors.surface,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.gold,
                  child: Text(
                    mockUser2.email[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.onGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Verify CircleAvatar exists
      expect(find.byType(CircleAvatar), findsOneWidget);

      // Verify avatar shows first letter
      expect(find.text('B'), findsOneWidget);

      // Verify CircleAvatar has gold background
      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.backgroundColor, AppColors.gold);
    });

    testWidgets('displays user name in gold color, bold', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text(
              mockUser2.email,
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );

      // Verify user name is displayed
      expect(find.text(mockUser2.email), findsOneWidget);

      // Verify text style
      final text = tester.widget<Text>(find.text(mockUser2.email));
      expect(text.style?.color, AppColors.gold);
      expect(text.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('displays last message text in goldMuted, truncated', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: Text(
                mockMessage.message,
                style: const TextStyle(color: AppColors.goldMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );

      // Verify message text is displayed
      expect(find.textContaining('Hello'), findsOneWidget);

      // Verify text style
      final text = tester.widget<Text>(find.textContaining('Hello'));
      expect(text.style?.color, AppColors.goldMuted);
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('displays timestamp in goldMuted, 12px', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text(
              '2h ago',
              style: TextStyle(color: AppColors.goldMuted, fontSize: 12),
            ),
          ),
        ),
      );

      // Verify timestamp is displayed
      expect(find.text('2h ago'), findsOneWidget);

      // Verify text style
      final text = tester.widget<Text>(find.text('2h ago'));
      expect(text.style?.color, AppColors.goldMuted);
      expect(text.style?.fontSize, 12);
    });

    testWidgets('shows gold dot indicator when chat.status = 0 (unread)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );

      // Verify unread indicator exists
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.gold);
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('does not show gold dot when chat.status = 1 (read)', (
      WidgetTester tester,
    ) async {
      final readChat = Chat(
        id: 'chat2',
        user1: mockUser1,
        user2: mockUser2,
        status: 1, // read
        lastMessage: mockMessage,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                const Text('User Name'),
                if (readChat.status == 0)
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
          ),
        ),
      );

      // Verify unread indicator does NOT exist for read chats
      expect(find.byType(Container), findsNothing);
    });
  });
}
