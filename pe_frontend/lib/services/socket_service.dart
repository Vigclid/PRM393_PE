import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;

enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<ConnectionState> _connectionStateController =
      StreamController<ConnectionState>.broadcast();

  /// Get the message stream for listening to incoming events
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// Get the connection state stream for monitoring connection status
  /// Task 7.4: Expose connection state for "Connecting..." indicator
  /// Validates: Requirements 2.4, 9.1
  Stream<ConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Connect to Socket.IO server with user ID
  /// Emits INIT event after connection is established
  Future<void> connect(String userId) async {
    if (_socket != null && _socket!.connected) {
      return; // Already connected
    }

    _connectionStateController.add(ConnectionState.connecting);

    // Task 7.3 & 7.4: Configure reconnection with exponential backoff
    // - Initial delay: 1000ms (1s)
    // - Max delay: 30000ms (30s)
    // - Max attempts: 5
    // - Exponential backoff: socket.io-client automatically doubles the delay
    //   Delays: 1s, 2s, 4s, 8s, 16s (capped at 30s)
    // Validates: Requirements 2.4, 2.5, 9.1
    _socket = IO.io(
      'http://192.168.1.18:8080',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(30000)
          .setReconnectionAttempts(5)
          .build(),
    );

    // Task 7.3: Listen for 'connect' event and emit INIT with userId
    // Validates: Requirements 2.2
    _socket!.onConnect((_) {
      print('Socket.IO connected');
      _connectionStateController.add(ConnectionState.connected);
      // Emit INIT event with userId to register connection on server
      _socket!.emit('data', jsonEncode({
        'type': 'INIT',
        'userId': userId,
      }));
    });

    // Task 7.3: Setup Socket.IO event listeners
    // This 'data' listener handles ALL incoming events from the server:
    // - MESSAGE: New message received from another user
    // - NEW_CHAT: New chat created (e.g., from auto thank you)
    // - UPDATE_CHAT: Chat status updated (e.g., marked as read)
    // All events are parsed and broadcast through messageStream for UI consumption
    _socket!.on('data', (data) {
      try {
        final parsed = jsonDecode(data as String);
        _messageController.add(parsed);
      } catch (e) {
        print('Error parsing socket data: $e');
      }
    });

    // Task 7.4: Listen for 'disconnect' event and update connection state
    // Reconnection is handled automatically by socket.io-client configuration
    // Validates: Requirements 2.4, 2.5, 9.1
    _socket!.onDisconnect((_) {
      print('Socket.IO disconnected');
      _connectionStateController.add(ConnectionState.disconnected);
    });

    // Task 7.4: Listen for 'reconnect_attempt' event to show reconnecting state
    // Validates: Requirements 2.4, 9.1
    _socket!.on('reconnect_attempt', (_) {
      print('Socket.IO reconnecting...');
      _connectionStateController.add(ConnectionState.reconnecting);
    });

    // Task 7.4: Listen for 'reconnect' event when reconnection succeeds
    // Validates: Requirements 2.4, 2.5
    _socket!.on('reconnect', (attemptNumber) {
      print('Socket.IO reconnected after $attemptNumber attempts');
      _connectionStateController.add(ConnectionState.connected);
    });

    // Task 7.4: Listen for 'reconnect_failed' event when max attempts exceeded
    // Validates: Requirements 2.4, 9.1
    _socket!.on('reconnect_failed', (_) {
      print('Socket.IO reconnection failed after max attempts');
      _connectionStateController.add(ConnectionState.disconnected);
    });

    _socket!.onConnectError((error) {
      print('Socket.IO connection error: $error');
      _connectionStateController.add(ConnectionState.disconnected);
    });

    _socket!.onError((error) {
      print('Socket.IO error: $error');
    });

    _socket!.connect();
  }

  /// Disconnect from Socket.IO server
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
  }

  /// Send a message via Socket.IO CHAT event
  void sendMessage(String from, String to, String message) {
    if (_socket == null || !_socket!.connected) {
      print('Socket not connected, cannot send message');
      return;
    }

    _socket!.emit('data', jsonEncode({
      'type': 'CHAT',
      'from': from,
      'to': to,
      'message': message,
    }));
  }

  /// Mark a message as read via Socket.IO MESSAGE_READ event
  void markAsRead(String messageId) {
    if (_socket == null || !_socket!.connected) {
      print('Socket not connected, cannot mark as read');
      return;
    }

    _socket!.emit('data', jsonEncode({
      'type': 'MESSAGE_READ',
      'messageId': messageId,
    }));
  }

  /// Check if socket is currently connected
  bool get isConnected => _socket != null && _socket!.connected;

  /// Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
    _connectionStateController.close();
  }
}
