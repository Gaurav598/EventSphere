import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/core/constants.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _messageController.stream;

  void connect() {
    if (_channel != null) return;
    
    // Parse the base URL from Constants to determine WS URL
    final baseUrl = Constants.baseUrl;
    final uri = Uri.parse(baseUrl);
    final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    // Base URL is usually http://localhost:8000/api/v1, we want ws://localhost:8000/ws
    final wsHost = uri.host;
    final wsPort = uri.port;
    final wsUrl = '$wsScheme://$wsHost:$wsPort/ws';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel!.stream.listen(
        (data) {
          try {
            final Map<String, dynamic> message = jsonDecode(data as String);
            _messageController.add(message);
          } catch (e) {
            debugPrint('Error parsing websocket message: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket Error: $error');
          _reconnect();
        },
        onDone: () {
          debugPrint('WebSocket closed');
          _reconnect();
        },
      );
    } catch (e) {
      debugPrint('WebSocket Connection Error: $e');
      _reconnect();
    }
  }

  void _reconnect() {
    _channel = null;
    // Attempt reconnect after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      connect();
    });
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
