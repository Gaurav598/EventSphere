import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/core/constants.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> setToken(String token) async {
    await _storage.write(key: Constants.tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: Constants.tokenKey);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: Constants.tokenKey);
  }
}
