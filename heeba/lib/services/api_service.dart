import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../models/profile.dart';
import '../models/user.dart';
import '../models/message.dart';

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

  // Fetch Filtered Profiles
  Future<List<Profile>> fetchFilteredProfiles({
    int? minAge,
    int? maxAge,
    String? gender,
    String? region,
    String? city,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token available');

    final queryParams = {
      if (minAge != null) 'min_age': minAge.toString(),
      if (maxAge != null) 'max_age': maxAge.toString(),
      if (gender != null) 'gender': gender,
      if (region != null) 'region': region,
      if (city != null) 'city': city,
    };

    final uri = Uri.parse('$baseUrl/profiles').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['profiles'] as List).map((json) => Profile.fromJson(json)).toList();
    } else {
      final error = _parseError(response.body, 'Failed to load profiles');
      print('Fetch profiles error: $error');
      throw Exception(error);
    }
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

  // Fetch Matches
  Future<List<Map<String, dynamic>>> fetchMatches() async {
    final token = await _getToken();
    if (token == null) throw Exception('No token available');

    final response = await http.get(
      Uri.parse('$baseUrl/matches'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> matchesJson = jsonDecode(response.body);
      print('Matches JSON response: $matchesJson');
      return matchesJson.map((json) {
        // Validate all required fields
        if (json['user_id'] == null ||
            json['match_id'] == null ||
            json['first_name'] == null ||
            json['last_name'] == null ||
            json['region'] == null ||
            json['city'] == null) {
          print('Skipping invalid match entry: $json');
          return null;
        }

        // Ensure integer fields are non-null and valid
        final int matchId = int.tryParse(json['match_id'].toString()) ?? 0;
        final int userId = int.tryParse(json['user_id'].toString()) ?? 0;
        final int age = int.tryParse(json['age'].toString()) ?? 0;

        if (matchId == 0 || userId == 0) {
          print('Skipping match entry with invalid IDs: $json');
          return null;
        }

        return {
          'match_id': matchId,
          'profile': Profile.fromJson({
            'id': matchId,
            'user_id': userId,
            'first_name': json['first_name'],
            'last_name': json['last_name'],
            'nickname': json['nickname'],
            'age': age,
            'gender': json['gender'],
            'bio': json['bio'],
            'region': json['region'],
            'city': json['city'],
            'pfp_path': json['pfp_path'],
          }),
        };
      }).where((entry) => entry != null).cast<Map<String, dynamic>>().toList();
    } else {
      final error = _parseError(response.body, 'Failed to fetch matches');
      print('Fetch matches error: $error');
      throw Exception(error);
    }
  }

  // Fetch Chat History
  Future<List<Message>> fetchChatHistory(int matchId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token available');

    final response = await http.get(
      Uri.parse('$baseUrl/messages/$matchId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['messages'] as List).map((json) => Message.fromJson(json)).toList();
    } else {
      final error = _parseError(response.body, 'Failed to fetch chat history');
      print('Fetch chat history error: $error');
      throw Exception(error);
    }
  }

  // Clear token (for logout)
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    print('Token cleared');
  }

  // Update Notification Preference
  Future<void> updateNotificationPreference(bool enabled) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token available');

    final response = await http.put(
      Uri.parse('$baseUrl/profile/notifications'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'notifications_enabled': enabled}),
    );

    if (response.statusCode != 200) {
      final error = _parseError(response.body, 'Failed to update notification preference');
      print('Update notification preference error: $error');
      throw Exception(error);
    }
  }

  // Change Password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token available');

    final response = await http.put(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final error = _parseError(response.body, 'Failed to change password');
      print('Change password error: $error');
      throw Exception(error);
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    final token = await _getToken();
    if (token == null) throw Exception('No token available');

    final response = await http.delete(
      Uri.parse('$baseUrl/auth/delete-account'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      final error = _parseError(response.body, 'Failed to delete account');
      print('Delete account error: $error');
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