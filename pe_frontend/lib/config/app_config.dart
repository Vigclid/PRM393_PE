import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  static late String _baseUrl;

  static Future<void> initialize() async {
    _baseUrl = await _loadBaseUrl();
  }

  static Future<String> _loadBaseUrl() async {
    try {
      // Đọc file .env từ thư mục gốc của project
      final envFile = File('.env');
      
      if (await envFile.exists()) {
        final content = await envFile.readAsString();
        final lines = content.split('\n');
        
        for (final line in lines) {
          if (line.startsWith('FLUTTER_APP_API_BASE_URL=')) {
            return line.split('=')[1].trim();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error reading .env file: $e');
      }
    }
    
    // Fallback URL nếu không tìm thấy .env
    return 'http://localhost:8080';
  }

  static String get baseUrl => _baseUrl;
}
