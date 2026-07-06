import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/core/secure_storage.dart';
import 'package:frontend/features/auth/models/user.dart';
import 'package:frontend/features/auth/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  
  User? _user;
  bool _isInitializing = true;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._authService) {
    checkAuthStatus();
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.role == 'admin';
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> checkAuthStatus() async {
    final token = await SecureStorage.getToken();
    if (token != null) {
      try {
        _user = await _authService.getMe();
      } catch (e) {
        await SecureStorage.clearToken();
        _user = null;
      }
    }
    _isInitializing = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final data = await _authService.login(email, password);
      final token = data['accessToken'];
      await SecureStorage.setToken(token);
      _user = await _authService.getMe();
      _setLoading(false);
      return true;
    } catch (e) {
      if (e is DioException && e.error is ApiException) {
        _error = (e.error as ApiException).message;
      } else {
        _error = 'Login failed. Please check credentials.';
      }
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, bool isAdmin) async {
    _setLoading(true);
    try {
      await _authService.register(name, email, password, role: isAdmin ? 'admin' : 'user');
      _setLoading(false);
      return true;
    } catch (e) {
      if (e is DioException && e.error is ApiException) {
        _error = (e.error as ApiException).message;
      } else {
        _error = 'Registration failed. User might exist.';
      }
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearToken();
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _error = null;
    notifyListeners();
  }
}
