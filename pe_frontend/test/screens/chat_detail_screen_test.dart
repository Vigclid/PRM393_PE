import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pe_frontend/models/chat.dart';
import 'package:pe_frontend/models/user.dart';
import 'package:pe_frontend/screens/chat_detail_screen.dart';
import 'package:pe_frontend/theme/app_theme.dart';
import 'package:pe_frontend/session/user_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('ChatDetailScreen - Task 11.1', () {
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

    final mockChat = Chat(
      id: 'chat1',
      user1: mockUser1,
      user2: mockUser2,
      status: 0,
      lastMessage: null,
    );

    setUp(() async {
      // Initialize SharedPreferences mock
      SharedPreferences.setMockInitialValues({});
      
      // Set up UserSession with mockUser1 as current user
      await UserSession.instance.login(
        token: 'test_token',
        user: mockUser1,
        rememberMe: false,
      );
    });

    tearDown(() async {
      // Clean up UserSession after each test
      await UserSession.instance.logout();
    });

    testWidgets('displays AppBar with back button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatDetailScreen(chat: mockChat),
        ),
      );

      // Verify AppBar exists
      expect(find.byType(AppBar), findsOneWidget);
      
      // Verify back button exists
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      
      // Verify back button has gold color
      final backButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.arrow_back),
      );
      expect(backButton.icon, isA<Icon>());
      final icon = backButton.icon as Icon;
      expect(icon.color, AppColors.gold);
    });

    testWidgets('displays other user\'s name in AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatDetailScreen(chat: mockChat),
        ),
      );

      // Verify other user's email is displayed (user2, since current user is user1)
      expect(find.text(mockUser2.email), findsOneWidget);
      
      // Verify title text style
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      final title = appBar.title as Text;
      expect(title.style?.color, AppColors.gold);
      expect(title.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('AppBar has surface background color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatDetailScreen(chat: mockChat),
        ),
      );

      // Verify AppBar background color
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, AppColors.surface);
    });

    testWidgets('Scaffold has background color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatDetailScreen(chat: mockChat),
        ),
      );

      // Verify Scaffold background color
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.background);
    });

    testWidgets('displays correct user when current user is user1', (WidgetTester tester) async {
      // Current user is user1 (set in setUp)
      await tester.pumpWidget(
        MaterialApp(
          home: ChatDetailScreen(chat: mockChat),
        ),
      );

      // Should display user2's email
      expect(find.text(mockUser2.email), findsOneWidget);
      expect(find.text(mockUser1.email), findsNothing);
    });

    testWidgets('displays correct user when current user is user2', (WidgetTester tester) async {
      // Change current user to user2
      await UserSession.instance.logout();
      await UserSession.instance.login(
        token: 'test_token',
        user: mockUser2,
        rememberMe: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatDetailScreen(chat: mockChat),
        ),
      );

      // Should display user1's email
      expect(find.text(mockUser1.email), findsOneWidget);
      expect(find.text(mockUser2.email), findsNothing);
    });

    testWidgets('back button navigates back', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(chat: mockChat),
                    ),
                  );
                },
                child: const Text('Open Chat'),
              ),
            ),
          ),
        ),
      );

      // Navigate to ChatDetailScreen
      await tester.tap(find.text('Open Chat'));
      await tester.pumpAndSettle();

      // Verify we're on ChatDetailScreen
      expect(find.byType(ChatDetailScreen), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify we're back to the previous screen
      expect(find.byType(ChatDetailScreen), findsNothing);
      expect(find.text('Open Chat'), findsOneWidget);
    });

    testWidgets('AppBar icon theme is gold', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatDetailScreen(chat: mockChat),
        ),
      );

      // Verify AppBar iconTheme
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.iconTheme?.color, AppColors.gold);
    });
  });
}
