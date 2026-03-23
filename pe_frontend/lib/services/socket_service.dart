import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';

/// Connection state enum for monitoring socket connection status
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// SocketService - Manages WebSocket (SockJS) connection for realtime chat
/// 
/// This service handles:
/// - Connection management with automatic reconnection
/// - Message sending and receiving via SockJS WebSocket
/// - Connection state monitoring
/// - Event broadcasting to UI components
/// 
/// Realtime Events Supported:
/// - MESSAGE: New message received from another user
/// - NEW_CHAT: New chat created (e.g., from auto thank you after checkout)
/// - UPDATE_CHAT: Chat status updated (e.g., marked as read)
/// - NOTIFICATION: Legacy notification events (for compatibility)
/// 
/// Tasks implemented:
/// - Task 7.2: SocketService class with connect/disconnect/sendMessage
/// - Task 7.3: WebSocket event listeners (MESSAGE, NEW_CHAT, UPDATE_CHAT)
/// - Task 7.4: Reconnection logic with exponential backoff
/// 
/// Usage Example:
/// ```dart
/// // Connect when user logs in
/// await SocketService().connect(userId);
/// 
/// // Listen to realtime events
/// SocketService().messageStream.listen((event) {
///   if (event['type'] == 'MESSAGE') {
///     // Handle new message
///   } else if (event['type'] == 'NEW_CHAT') {
///     // Handle new chat
///   }
/// });
/// 
/// // Send a message
/// SocketService().sendMessage(fromUserId, toUserId, messageText);
/// 
/// // Disconnect when user logs out
/// SocketService().disconnect();
/// ```
class SocketService {
  static final SocketService _instance = SocketService._internal();
  
  /// Singleton instance accessor
  factory SocketService() => _instance;
  
  /// Named instance accessor for compatibility with existing code
  static SocketService get instance => _instance;
  
  SocketService._internal();

  WebSocketChannel? _channel;
  String? _currentUserId;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _isManualDisconnect = false;
  
  /// Stream controller for all incoming Socket.IO events
  /// Broadcasts: MESSAGE, NEW_CHAT, UPDATE_CHAT, NOTIFICATION events
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  
  /// Stream controller for connection state changes
  /// Used for showing "Connecting..." indicators in UI
  final StreamController<ConnectionState> _connectionStateController =
      StreamController<ConnectionState>.broadcast();

  /// Get the message stream for listening to incoming events
  /// UI components subscribe to this stream to receive realtime updates
  /// 
  /// Event types:
  /// - MESSAGE: { type: 'MESSAGE', message: {...}, timestamp: ... }
  /// - NEW_CHAT: { type: 'NEW_CHAT', chat: {...} }
  /// - UPDATE_CHAT: { type: 'UPDATE_CHAT', chat: {...} }
  /// - NOTIFICATION: { type: 'NOTIFICATION', ... }
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  
  /// Alias for compatibility with existing notification code
  Stream<Map<String, dynamic>> get notificationStream => _messageController.stream;

  /// Get the connection state stream for monitoring connection status
  /// Task 7.4: Expose connection state for "Connecting..." indicator
  /// Validates: Requirements 2.4, 9.1
  Stream<ConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Connect to SockJS WebSocket server with user ID
  /// Emits INIT event after connection is established
  /// 
  /// Task 7.2: Implement connect method with userId parameter
  /// Task 7.3: Setup event listeners after connection
  /// Task 7.4: Configure reconnection with exponential backoff
  /// Validates: Requirements 2.1, 2.2, 2.4, 2.5
  /// 
  /// Parameters:
  /// - userId: The authenticated user's ID to register this connection
  /// 
  /// Reconnection Strategy:
  /// - Initial delay: 1000ms (1s)
  /// - Max delay: 30000ms (30s)
  /// - Max attempts: 5
  /// - Exponential backoff: 1s → 2s → 4s → 8s → 16s (capped at 30s)
  Future<void> connect(String userId) async {
    if (_channel != null && isConnected) {
      // Already connected, just update userId if different
      if (_currentUserId != userId) {
        _currentUserId = userId;
        _sendData({
          'type': 'INIT',
          'userId': userId,
        });
      }
      return;
    }

    _currentUserId = userId;
    _isManualDisconnect = false;
    _connectionStateController.add(ConnectionState.connecting);

    try {
      // SockJS WebSocket URL format: ws://host:port/ws/xxx/yyy
      // The xxx and yyy are random strings required by SockJS protocol
      final random1 = DateTime.now().millisecondsSinceEpoch.toString();
      final random2 = (DateTime.now().millisecondsSinceEpoch + 1).toString();
      final wsUrl = AppConfig.socketUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://');
      final sockJsUrl = '$wsUrl/ws/$random1/$random2/websocket';
      
      print('Connecting to SockJS: $sockJsUrl');
      
      _channel = WebSocketChannel.connect(Uri.parse(sockJsUrl));
      
      // Listen to incoming messages
      _channel!.stream.listen(
        (message) {
          _handleMessage(message as String);
        },
        onError: (error) {
          print('WebSocket error: $error');
          _connectionStateController.add(ConnectionState.disconnected);
          _attemptReconnect();
        },
        onDone: () {
          print('WebSocket connection closed');
          _connectionStateController.add(ConnectionState.disconnected);
          if (!_isManualDisconnect) {
            _attemptReconnect();
          }
        },
      );
      
      // Connection successful
      _reconnectAttempts = 0;
      _connectionStateController.add(ConnectionState.connected);
      print('WebSocket connected');
      
      // Send INIT event to register user
      _sendData({
        'type': 'INIT',
        'userId': userId,
      });
      
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      _connectionStateController.add(ConnectionState.disconnected);
      _attemptReconnect();
    }
  }
  
  /// Handle incoming WebSocket messages
  /// SockJS sends messages in array format: ["content"]
  void _handleMessage(String message) {
    try {
      // SockJS wraps messages in arrays, so we need to unwrap first
      // Format from server: ["{"type":"MESSAGE",...}"]
      if (message.startsWith('[') && message.endsWith(']')) {
        final List<dynamic> array = jsonDecode(message);
        if (array.isNotEmpty) {
          final String content = array[0] as String;
          final parsed = jsonDecode(content);
          _messageController.add(parsed);
          print('Socket event received: ${parsed['type']}');
        }
      } else {
        // Fallback: try to parse directly
        final parsed = jsonDecode(message);
        _messageController.add(parsed);
        print('Socket event received: ${parsed['type']}');
      }
    } catch (e) {
      print('Error parsing socket data: $e');
      print('Raw message: $message');
    }
  }
  
  /// Send data through WebSocket
  /// SockJS requires messages to be sent in array format: ["content"]
  void _sendData(Map<String, dynamic> data) {
    if (_channel == null || !isConnected) {
      print('WebSocket not connected, cannot send data');
      return;
    }
    
    try {
      // SockJS protocol: wrap message in array format
      // Format: ["{"type":"CHAT","from":"...","to":"...","message":"..."}"]
      final jsonString = jsonEncode(data);
      final sockJsMessage = jsonEncode([jsonString]);
      
      print('Sending SockJS message: $sockJsMessage');
      _channel!.sink.add(sockJsMessage);
    } catch (e) {
      print('Error sending data: $e');
    }
  }
  
  /// Attempt to reconnect with exponential backoff
  void _attemptReconnect() {
    if (_isManualDisconnect) {
      return;
    }
    
    if (_reconnectAttempts >= AppConfig.socketReconnectionAttempts) {
      print('Max reconnection attempts reached');
      _connectionStateController.add(ConnectionState.disconnected);
      return;
    }
    
    _reconnectAttempts++;
    _connectionStateController.add(ConnectionState.reconnecting);
    
    // Calculate delay with exponential backoff
    final delay = AppConfig.socketReconnectionDelay * (1 << (_reconnectAttempts - 1));
    final cappedDelay = delay > AppConfig.socketReconnectionDelayMax 
        ? AppConfig.socketReconnectionDelayMax 
        : delay;
    
    print('Reconnecting in ${cappedDelay}ms (attempt $_reconnectAttempts)');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: cappedDelay), () {
      if (_currentUserId != null) {
        connect(_currentUserId!);
      }
    });
  }

  /// Disconnect from WebSocket server
  /// Task 7.2: Implement disconnect method
  /// Validates: Requirements 2.1
  /// 
  /// Call this when:
  /// - User logs out
  /// - App is being closed
  /// - Need to switch to a different user
  void disconnect() {
    _isManualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
      _currentUserId = null;
      _connectionStateController.add(ConnectionState.disconnected);
    }
  }

  /// Send a message via WebSocket CHAT event
  /// Task 7.2: Implement sendMessage method for CHAT events
  /// Validates: Requirements 2.3, 4.3
  /// 
  /// Parameters:
  /// - from: Sender's user ID (current user)
  /// - to: Receiver's user ID (other user in chat)
  /// - message: Message text content
  /// 
  /// Backend will:
  /// 1. Save message to database
  /// 2. Emit MESSAGE event to receiver
  /// 3. Update chat status to unread
  /// 
  /// Example:
  /// ```dart
  /// SocketService().sendMessage(
  ///   currentUserId,
  ///   otherUserId,
  ///   'Hello, how are you?'
  /// );
  /// ```
  void sendMessage(String from, String to, String message) {
    _sendData({
      'type': 'CHAT',
      'from': from,
      'to': to,
      'message': message,
    });
    
    print('Message sent: from=$from, to=$to');
  }

  /// Mark a message as read via WebSocket MESSAGE_READ event
  /// Task 7.2: Implement markAsRead method for MESSAGE_READ events
  /// Validates: Requirements 4.3
  /// 
  /// Parameters:
  /// - messageId: The ID of the message to mark as read
  /// 
  /// Backend will:
  /// 1. Update message.isRead to 1
  /// 2. Check if all messages in chat are read
  /// 3. Update chat.status to 1 if all read
  /// 4. Emit UPDATE_CHAT event to both users
  /// 
  /// Example:
  /// ```dart
  /// SocketService().markAsRead(messageId);
  /// ```
  void markAsRead(String messageId) {
    _sendData({
      'type': 'MESSAGE_READ',
      'messageId': messageId,
    });
    
    print('Message marked as read: $messageId');
  }

  /// Check if socket is currently connected
  /// Returns true if connected, false otherwise
  bool get isConnected => _channel != null;
  
  /// Get current connected user ID
  /// Returns null if not connected
  String? get currentUserId => _currentUserId;

  /// Dispose resources
  /// Closes all stream controllers and disconnects socket
  /// 
  /// Call this when:
  /// - App is being disposed
  /// - Service is no longer needed
  /// 
  /// Note: Usually not needed as this is a singleton service
  void dispose() {
    disconnect();
    _messageController.close();
    _connectionStateController.close();
  }
}
