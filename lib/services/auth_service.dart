import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class AuthService {
  static const String _userSessionKey = 'user_session';
  static const String _isLoggedInKey = 'is_logged_in';

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Hash password for security
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Login user
  Future<AuthResult> login(String username, String password) async {
    try {
      final user = await _dbHelper.getUserByUsername(username);

      if (user == null) {
        return AuthResult(success: false, message: 'User not found');
      }

      // For demo purposes, using plain text password
      // In production, compare hashed passwords
      if (user.password != password) {
        return AuthResult(success: false, message: 'Invalid password');
      }

      if (!user.isActive) {
        return AuthResult(success: false, message: 'Account is deactivated');
      }

      // Save session
      await _saveUserSession(user);

      return AuthResult(success: true, message: 'Login successful', user: user);
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Login failed: ${e.toString()}',
      );
    }
  }

  // Register new user (admin only)
  Future<AuthResult> register(User user) async {
    try {
      // Check if username already exists
      final existingUser = await _dbHelper.getUserByUsername(user.username);
      if (existingUser != null) {
        return AuthResult(success: false, message: 'Username already exists');
      }

      // Hash password before saving
      final hashedPassword = _hashPassword(user.password);
      final userWithHashedPassword = user.copyWith(password: hashedPassword);

      final userId = await _dbHelper.insertUser(userWithHashedPassword);

      if (userId > 0) {
        return AuthResult(
          success: true,
          message: 'User registered successfully',
          user: userWithHashedPassword.copyWith(id: userId),
        );
      } else {
        return AuthResult(success: false, message: 'Failed to register user');
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Registration failed: ${e.toString()}',
      );
    }
  }

  // Get current logged-in user
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userSessionKey);

      if (userJson != null) {
        final userMap = json.decode(userJson);
        return User.fromMap(userMap);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Save user session
  Future<void> _saveUserSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(user.toMap());

    await prefs.setString(_userSessionKey, userJson);
    await prefs.setBool(_isLoggedInKey, true);
  }

  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userSessionKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  // Change password
  Future<AuthResult> changePassword(
    int userId,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      // Get user by ID (assuming we have such method)
      final users = await _dbHelper.getAllUsers();
      final user = users.firstWhere((u) => u.id == userId);

      // Verify old password
      if (user.password != oldPassword) {
        return AuthResult(
          success: false,
          message: 'Current password is incorrect',
        );
      }

      // Hash new password
      final hashedNewPassword = _hashPassword(newPassword);
      final updatedUser = user.copyWith(
        password: hashedNewPassword,
        updatedAt: DateTime.now(),
      );

      await _dbHelper.updateUser(updatedUser);

      // Update session
      await _saveUserSession(updatedUser);

      return AuthResult(
        success: true,
        message: 'Password changed successfully',
        user: updatedUser,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to change password: ${e.toString()}',
      );
    }
  }

  // Get all users (admin only)
  Future<List<User>> getAllUsers() async {
    return await _dbHelper.getAllUsers();
  }

  // Update user (admin only)
  Future<AuthResult> updateUser(User user) async {
    try {
      final result = await _dbHelper.updateUser(user);

      if (result > 0) {
        return AuthResult(
          success: true,
          message: 'User updated successfully',
          user: user,
        );
      } else {
        return AuthResult(success: false, message: 'Failed to update user');
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Update failed: ${e.toString()}',
      );
    }
  }

  // Delete user (admin only)
  Future<AuthResult> deleteUser(int userId) async {
    try {
      final result = await _dbHelper.deleteUser(userId);

      if (result > 0) {
        return AuthResult(success: true, message: 'User deleted successfully');
      } else {
        return AuthResult(success: false, message: 'Failed to delete user');
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Delete failed: ${e.toString()}',
      );
    }
  }
}

class AuthResult {
  final bool success;
  final String message;
  final User? user;

  AuthResult({required this.success, required this.message, this.user});
}
