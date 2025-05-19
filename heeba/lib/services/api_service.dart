import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000';

  // Save token
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    print('Token saved: $token');
  }

  // Get token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('Retrieved token: $token');
    return token;
  }

  // Sign Up
  Future<User> signup(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _saveToken(data['token']);
      return User.fromJson(data['user']);
    } else {
      final error = _parseError(response.body, 'Signup failed');
      print('Signup error: $error');
      throw Exception(error);
    }
  }

  // Login
  Future<User> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveToken(data['token']);
      return User.fromJson(data['user']);
    } else {
      final error = _parseError(response.body, 'Login failed');
      print('Login error: $error');
      throw Exception(error);
    }
  }

  // Helper to parse error messages safely
  String _parseError(String responseBody, String defaultError) {
    try {
      final data = jsonDecode(responseBody);
      return data['error']?.toString() ?? defaultError;
    } catch (_) {
      return defaultError;
    }
  }
}