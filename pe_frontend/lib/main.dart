import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/statistics_screen.dart';
import 'session/user_session.dart';
import 'theme/app_theme.dart';
import 'theme/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserSession.instance.tryRestoreSession();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([UserSession.instance, ThemeNotifier.instance]),
      builder: (context, _) {
        return MaterialApp(
          title: 'PE App',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeNotifier.instance.mode,
          debugShowCheckedModeBanner: false,
          home: _homeScreen,
        );
      },
    );
  }

  Widget get _homeScreen {
    final session = UserSession.instance;
    if (!session.isLoggedIn) return const LoginScreen();
    final isAdmin = session.currentUser!.roleName.toLowerCase() == 'admin';
    return isAdmin ? const StatisticsScreen() : const MainScreen();
  }
}
