
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../models/profile.dart';
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

  // Clear token (for logout)
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    print('Token cleared');
  }

  // Check Profile Existence
  Future<bool> checkProfile() async {
    final token = await _getToken();
    if (token == null) {
      print('No token found for profile check');
      throw Exception('No token available');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/profile/check'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print('Profile check response: ${response.statusCode} ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['hasProfile'] ?? false;
    } else {
      final error = _parseError(response.body, 'Failed to check profile');
      print('Check profile error: $error');
      throw Exception(error);
    }
  }

  // Create/Update Profile
  Future<void> saveProfile({
    required String firstName,
    required String lastName,
    String? nickname,
    required int age,
    String? gender,
    String? bio,
    required String region,
    required String city,
    PlatformFile? pfp,
  }) async {
    final token = await _getToken();
    if (token == null) {
      print('No token for profile creation');
      throw Exception('No token available');
    }

    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/profile'));
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['first_name'] = firstName;
    request.fields['last_name'] = lastName;
    if (nickname != null) request.fields['nickname'] = nickname;
    request.fields['age'] = age.toString();
    if (gender != null) request.fields['gender'] = gender;
    if (bio != null) request.fields['bio'] = bio;
    request.fields['region'] = region;
    request.fields['city'] = city;

    if (pfp != null && pfp.path != null) {
      request.files.add(await http.MultipartFile.fromPath('pfp', pfp.path!));
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

print('Save profile response: ${response.statusCode} $responseBody');

    if (response.statusCode != 201) {
      final error = _parseError(responseBody, 'Failed to save profile');
      print('Save profile error: $error');
      throw Exception(error);
    }
  }

  // Get Current User's Profile
  Future<Profile> getCurrentProfile() async {
    final token = await _getToken();
    if (token == null) throw Exception('No token available');

    final response = await http.get(
      Uri.parse('$baseUrl/profile/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Profile.fromJson(data);
    } else {
      final error = _parseError(response.body, 'Failed to load profile');
      print('Get current profile error: $error');
      throw Exception(error);
    }
  }

  // Record Swipe
  Future<void> recordSwipe(int targetUserId, String swipeType) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token available');

    final response = await http.post(
      Uri.parse('$baseUrl/swipe'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'target_user_id': targetUserId,
        'swipe_type': swipeType,
      }),
    );

    if (response.statusCode != 201) {
      final error = _parseError(response.body, 'Failed to record swipe');
      print('Swipe error: $error');
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