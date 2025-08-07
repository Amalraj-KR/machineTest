import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      try {
        final userData = jsonDecode(userJson);
        _user = User.fromJson(userData);

        notifyListeners();

        // Verify token is still valid
        await _refreshUserData();
      } catch (e) {
        await logout();
      }
    }
  }

  Future<void> _refreshUserData() async {
    if (_user?.token != null) {
      try {
        final updatedUser = await AuthService.getCurrentUser(_user!.token);
        _user = updatedUser;
        await _saveUserToPrefs();
        notifyListeners();
      } catch (e) {
        // Token might be expired, try refresh
        if (_user?.refreshToken != null) {
          try {
            final refreshedUser = await AuthService.refreshToken(
              _user!.refreshToken,
            );
            _user = refreshedUser;
            await _saveUserToPrefs();
            notifyListeners();
          } catch (refreshError) {
            await logout();
          }
        } else {
          await logout();
        }
      }
    }
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await AuthService.login(username, password);
      await _saveUserToPrefs();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _user = null;
    _error = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    notifyListeners();
  }

  Future<void> _saveUserToPrefs() async {
    if (_user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_user!.toJson()));
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
