import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'dart:convert';

class StorageService {
  static const String _keyUser = 'current_user';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyToken = 'auth_token';

  static Future<void> saveUser(User user, {String? token}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, json.encode(user.toJson()));
    await prefs.setBool(_keyIsLoggedIn, true);
    if (token != null) {
      await prefs.setString(_keyToken, token);
    }
  }

  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_keyUser);
    if (userJson != null) {
      return User.fromJson(json.decode(userJson) as Map<String, dynamic>);
    }
    return null;
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Clear all data (logout)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<int?> getCurrentUserId() async {
    final user = await getCurrentUser();
    return user?.id;
  }

  static Future<String?> getClassName() async {
    final user = await getCurrentUser();
    return user?.className;
  }

  static Future<UserRole?> getUserRole() async {
    final user = await getCurrentUser();
    if (user != null && user.roles.isNotEmpty) {
      return user.roles.first;
    }
    return null;
  }

  static Future<bool> isTeacher() async {
    final user = await getCurrentUser();
    return user?.isTeacher ?? false;
  }

  static Future<bool> isStudent() async {
    final user = await getCurrentUser();
    return user?.isStudent ?? false;
  }
}
