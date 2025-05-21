import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../services/api_service.dart';

class ProfileProvider with ChangeNotifier {
  List<Profile> _profiles = [];
  bool _isLoading = false;
  String? _error;

  List<Profile> get profiles => _profiles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProfiles({
    int? minAge,
    int? maxAge,
    String? gender,
    String? region,
    String? city,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profiles = await ApiService().fetchFilteredProfiles(
        minAge: minAge,
        maxAge: maxAge,
        gender: gender,
        region: region,
        city: city,
      );
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _profiles = [];
    }

    _isLoading = false;
    notifyListeners();
  }
}