import '../services/socket_service.dart';
import '../session/user_session.dart';

/// Helper class to manage Socket.IO connection lifecycle
class SocketHelper {
  /// Ensure socket is connected for current user
  /// Call this when:
  /// - User logs in
  /// - App resumes from background
  /// - Before sending messages
  static Future<void> ensureConnected() async {
    final userId = UserSession.instance.currentUser?.id;
    if (userId == null) {
      print('Cannot connect socket: No user logged in');
      return;
    }
    
    if (!SocketService().isConnected) {
      print('Socket not connected, connecting now...');
      try {
        await SocketService().connect(userId);
        print('Socket connection initiated for user: $userId');
      } catch (e) {
        print('Error connecting socket: $e');
      }
    } else {
      print('Socket already connected');
    }
  }
  
  /// Disconnect socket
  /// Call this when:
  /// - User logs out
  /// - App is closing
  static void disconnect() {
    SocketService().disconnect();
    print('Socket disconnected');
  }
  
  /// Check if socket is connected
  static bool get isConnected => SocketService().isConnected;
  
  /// Get connection state stream
  static Stream<ConnectionState> get connectionStateStream =>
      SocketService().connectionStateStream;
}
