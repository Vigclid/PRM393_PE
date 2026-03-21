import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Connects to the SockJS server via raw WebSocket transport.
/// SockJS WebSocket URL: ws://host/prefix/{server}/{session}/websocket
class SocketService {
  static final SocketService instance = SocketService._();
  SocketService._();

  WebSocket? _socket;
  String? _userId;
  bool _connected = false;

  final _notifController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notificationStream =>
      _notifController.stream;

  bool get isConnected => _connected;

  Future<void> connect(String userId) async {
    if (_connected) return;
    _userId = userId;

    final session = _randomString(8);
    final url = 'ws://10.0.2.2:8080/ws/000/$session/websocket';

    try {
      _socket = await WebSocket.connect(url);
      _connected = true;
      _socket!.listen(
        _onMessage,
        onDone: _onClose,
        onError: (_) => _onClose(),
        cancelOnError: false,
      );
    } catch (_) {
      _connected = false;
    }
  }

  void _onMessage(dynamic raw) {
    if (raw is! String) return;

    if (raw == 'o') {
      // SockJS handshake — register this connection with our userId
      _send({'type': 'INIT', 'userId': _userId});
    } else if (raw == 'h') {
      // SockJS heartbeat — no action needed
    } else if (raw.startsWith('a')) {
      // SockJS message frame: a["<json-encoded-string>", ...]
      try {
        final arr = jsonDecode(raw.substring(1)) as List<dynamic>;
        for (final item in arr) {
          final msg = jsonDecode(item as String) as Map<String, dynamic>;
          if (msg['type'] == 'NOTIFICATION') {
            _notifController.add(msg);
          }
        }
      } catch (_) {}
    }
  }

  void _send(Map<String, dynamic> data) {
    if (_socket == null) return;
    // SockJS client sends messages as an array of JSON-encoded strings
    _socket!.add(jsonEncode([jsonEncode(data)]));
  }

  void _onClose() {
    _connected = false;
    _socket = null;
  }

  void disconnect() {
    _socket?.close();
    _connected = false;
    _socket = null;
  }

  static String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    return List.generate(
      length,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
  }
}
