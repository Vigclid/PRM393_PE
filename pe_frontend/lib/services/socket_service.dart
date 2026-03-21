import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Get the message stream for listening to incoming events
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// Connect to Socket.IO server with user ID
  /// Emits INIT event after connection is established
  Future<void> connect(String userId) async {
    if (_socket != null && _socket!.connected) {
      return; // Already connected
    }

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

    _socket!.onConnect((_) {
      print('Socket.IO connected');
      // Emit INIT event with userId
      _socket!.emit('data', jsonEncode({
        'type': 'INIT',
        'userId': userId,
      }));
    });

    _socket!.on('data', (data) {
      try {
        final parsed = jsonDecode(data as String);
        _messageController.add(parsed);
      } catch (e) {
        print('Error parsing socket data: $e');
      }
    });

    _socket!.onDisconnect((_) {
      print('Socket.IO disconnected');
    });

    _socket!.onConnectError((error) {
      print('Socket.IO connection error: $error');
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
  }
}
