import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// Keys used in SharedPreferences storage.
abstract class _Keys {
  static const token = 'session_token';
  static const user = 'session_user';
  static const rememberMe = 'session_remember_me';
}

/// Global user session. Holds the authenticated user and access token.
///
/// Usage anywhere in the app:
///   UserSession.instance.currentUser
///   UserSession.instance.accessToken
///   UserSession.instance.isLoggedIn
///
/// Listen to changes via [ListenableBuilder] or [ChangeNotifier].
class UserSession extends ChangeNotifier {
  UserSession._();

  static final UserSession instance = UserSession._();

  User? _currentUser;
  String? _accessToken;

  User? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get isLoggedIn => _accessToken != null && _currentUser != null;

  /// Called once at app startup. Restores session from SharedPreferences
  /// only if the user had previously chosen "Remember me".
  Future<void> tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getBool(_Keys.rememberMe) ?? false;
    if (!remembered) return;

    final token = prefs.getString(_Keys.token);
    final userJson = prefs.getString(_Keys.user);
    if (token == null || userJson == null) return;

    try {
      final user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      _accessToken = token;
      _currentUser = user;
      // No notifyListeners() here — called before runApp, no listeners yet.
    } catch (_) {
      // Corrupt stored data — clear it.
      await _clearPrefs(prefs);
    }
  }

  /// Call after a successful login.
  Future<void> login({
    required String token,
    required User user,
    required bool rememberMe,
  }) async {
    _accessToken = token;
    _currentUser = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_Keys.rememberMe, rememberMe);
    if (rememberMe) {
      await prefs.setString(_Keys.token, token);
      await prefs.setString(_Keys.user, jsonEncode(user.toJson()));
    }

    notifyListeners();
  }

  /// Call to log out the user.
  Future<void> logout() async {
    _accessToken = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await _clearPrefs(prefs);
    notifyListeners();
  }

  Future<void> _clearPrefs(SharedPreferences prefs) async {
    await prefs.remove(_Keys.token);
    await prefs.remove(_Keys.user);
    await prefs.remove(_Keys.rememberMe);
  }
}
