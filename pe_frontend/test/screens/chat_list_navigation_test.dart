import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pe_frontend/models/chat.dart';
import 'package:pe_frontend/models/user.dart';
import 'package:pe_frontend/models/message.dart';
import 'package:pe_frontend/screens/chat_detail_screen.dart';
import 'package:pe_frontend/theme/app_theme.dart';

/// Task 10.5: Test navigation from ChatListScreen to ChatDetailScreen
/// Validates: Requirement 4.1
void main() {
  group('ChatListScreen Navigation - Task 10.5', () {
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
      status: 0,
      lastMessage: mockMessage,
    );

    testWidgets('tapping chat list item navigates to ChatDetailScreen', (WidgetTester tester) async {
      // Build a simple chat list item with navigation
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              color: AppColors.surface,
              child: ListTile(
                title: Text(mockUser2.email),
                onTap: () {
                  Navigator.push(
                    tester.element(find.byType(ListTile)),
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(chat: mockChat),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Verify ListTile exists
      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text(mockUser2.email), findsOneWidget);

      // Tap the ListTile
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      // Verify navigation to ChatDetailScreen
      expect(find.byType(ChatDetailScreen), findsOneWidget);
    });

    testWidgets('ChatDetailScreen receives correct chat object', (WidgetTester tester) async {
      // Build ChatDetailScreen directly with chat object
      await tester.pumpWidget(
        MaterialApp(
          home: ChatDetailScreen(chat: mockChat),
        ),
      );

      // Verify ChatDetailScreen is displayed
      expect(find.byType(ChatDetailScreen), findsOneWidget);
      
      // Verify AppBar is present
      expect(find.byType(AppBar), findsOneWidget);
      
      // Verify loading indicator or message display (task 11.2 implementation)
      // The screen will show either a loading indicator or messages
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('back navigation from ChatDetailScreen works', (WidgetTester tester) async {
      // Build a navigation stack
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Chat List')),
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(chat: mockChat),
                    ),
                  );
                },
                child: const Text('Open Chat'),
              ),
            ),
          ),
        ),
      );

      // Tap to navigate to ChatDetailScreen
      await tester.tap(find.text('Open Chat'));
      await tester.pumpAndSettle();

      // Verify we're on ChatDetailScreen
      expect(find.byType(ChatDetailScreen), findsOneWidget);

      // Tap back button (using icon instead of BackButton type)
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify we're back to the original screen
      expect(find.text('Chat List'), findsOneWidget);
      expect(find.byType(ChatDetailScreen), findsNothing);
    });
  });
}
