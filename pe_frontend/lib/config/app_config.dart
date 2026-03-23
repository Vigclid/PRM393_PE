/// Application configuration
///
/// Centralized configuration for API endpoints, Socket.IO URLs, and other app settings.
/// Change baseUrl here to update both REST API and Socket.IO connections.
class AppConfig {
  /// Base URL for backend server
  ///
  /// Examples:
  /// - Local development: 'http://192.168.1.79:8080'
  /// - Android emulator: 'http://10.0.2.2:8080'
  /// - iOS simulator: 'http://localhost:8080'
  /// - Production: 'https://api.yourapp.com'
  static const String baseUrl = 'http://10.0.2.2:8080';

  /// Socket.IO URL (same as baseUrl for most cases)
  /// Override this if Socket.IO is on a different server
  static const String socketUrl = baseUrl;

  /// API timeout duration
  static const Duration apiTimeout = Duration(seconds: 30);

  /// Socket.IO reconnection settings
  static const int socketReconnectionDelay = 1000; // 1 second
  static const int socketReconnectionDelayMax = 30000; // 30 seconds
  static const int socketReconnectionAttempts = 5;

  /// Environment helpers
  static bool get isDevelopment =>
      baseUrl.contains('192.168') ||
      baseUrl.contains('localhost') ||
      baseUrl.contains('10.0.2.2');

  static bool get isProduction => !isDevelopment;
}
