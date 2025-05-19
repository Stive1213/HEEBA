import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final _minAgeController = TextEditingController(text: '18');
  final _maxAgeController = TextEditingController(text: '35');
  String? _region;
  String? _city;
  List<Profile> _profiles = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  Timer? _debounce;

  final Map<String, List<String>> _regionCities = {
    'Addis Ababa': ['Addis Ababa', 'Bole'],
    'Dire Dawa': ['Dire Dawa'],
    'Afar': ['Semera', 'Asaita'],
    'Amhara': ['Bahir Dar', 'Gondar'],
    'Oromia': ['Adama', 'Jimma'],
    'Somali': ['Jijiga', 'Gode'],
    'Benishangul-Gumuz': ['Assosa'],
    'Gambella': ['Gambella'],
    'Sidama': ['Hawassa'],
    'Tigray': ['Mekelle', 'Adigrat'],
    'SNNPR': ['Arba Minch', 'Wolaita Sodo'],
    'South West Ethiopia Peoples Region': ['Bonga'],
    'Harari': ['Harar'],
    'Central Ethiopia Region': ['Bishoftu'],
  };

  Future<void> _fetchProfiles() async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final minAge = int.tryParse(_minAgeController.text);
        final maxAge = int.tryParse(_maxAgeController.text);

        if (minAge == null || maxAge == null || minAge < 18 || maxAge < minAge) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFFF8787),
              content: const Text('Please enter a valid age range (18+ and min ≤ max)'),
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        final currentProfile = await apiService.getCurrentProfile();
        final targetGender = currentProfile.gender == 'Male' ? 'Female' : 'Male';

        final profiles = await apiService.fetchFilteredProfiles(
          minAge: minAge,
          maxAge: maxAge,
          gender: targetGender,
          region: _region,
          city: _city,
        );

        if (mounted) {
          setState(() {
            _profiles = profiles;
            _currentIndex = 0;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFFF8787),
              content: Text('Failed to load profiles: ${e.toString().replaceAll('Exception: ', '')}'),
            ),
          );
        }
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  void _swipe(Profile profile, String swipeType) async {
    try {
      await Provider.of<ApiService>(context, listen: false).recordSwipe(
        profile.userId,
        swipeType,
      );
      if (mounted) {
        setState(() {
          if (_currentIndex < _profiles.length - 1) {
            _currentIndex++;
          } else {
            _profiles = [];
            _currentIndex = 0;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFFF8787),
            content: Text('Failed to record swipe: ${e.toString().replaceAll('Exception: ', '')}'),
          ),
        );
      }
    }
  }

  void _handleButtonSwipe(bool isRight) {
    if (_profiles.isEmpty || _currentIndex >= _profiles.length) return;
    final profile = _profiles[_currentIndex];
    final swipeType = isRight ? 'right' : 'left';
    _swipe(profile, swipeType);
  }

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  @override
  void dispose() {
    _minAgeController.dispose();
    _maxAgeController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: const Color(0xFFFF6B6B), // Blush pink
        scaffoldBackgroundColor: const Color(0xFFF8F1F1), // Off-white
        textTheme: Theme.of(context).textTheme.copyWith(
              bodyMedium: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Color(0xFF1A1A40), // Deep navy
              ),
              labelMedium: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Colors.grey,
              ),
              titleLarge: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A40),
              ),
            ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 5,
            shadowColor: Colors.black.withOpacity(0.2),
            textStyle: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFEDEDED)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
          ),
          labelStyle: const TextStyle(
            fontFamily: 'Roboto',
            color: Colors.grey,
          ),
          errorStyle: const TextStyle(
            fontFamily: 'Roboto',
            color: Color(0xFFFF8787), // Coral for errors
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Swipe',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFF6B6B),
          elevation: 0,
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFF8787)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Filter Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _minAgeController,
                                decoration: const InputDecoration(
                                  labelText: 'Min Age',
                                  prefixIcon: Icon(Icons.person, color: Color(0xFFFF6B6B)),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Enter min age';
                                  final age = int.tryParse(value);
                                  if (age == null || age < 18) return 'Must be 18+';
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _maxAgeController,
                                decoration: const InputDecoration(
                                  labelText: 'Max Age',
                                  prefixIcon: Icon(Icons.person, color: Color(0xFFFF6B6B)),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Enter max age';
                                  final age = int.tryParse(value);
                                  if (age == null || age < int.tryParse(_minAgeController.text)!) {
                                    return 'Max age must be ≥ min age';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _region,
                          decoration: const InputDecoration(
                            labelText: 'Region',
                            prefixIcon: Icon(Icons.location_on, color: Color(0xFFFF6B6B)),
                          ),
                          items: _regionCities.keys
                              .map((region) => DropdownMenuItem(
                                    value: region,
                                    child: Text(region),
                                  ))
                              .toList(),
                          onChanged: (value) => setState(() {
                            _region = value;
                            _city = null;
                          }),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _city,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            prefixIcon: Icon(Icons.location_city, color: Color(0xFFFF6B6B)),
                          ),
                          items: _region == null
                              ? []
                              : _regionCities[_region]!
                                  .map((city) => DropdownMenuItem(
                                        value: city,
                                        child: Text(city),
                                      ))
                                  .toList(),
                          onChanged: (value) => setState(() => _city = value),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _fetchProfiles();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                          shadowColor: Colors.black.withOpacity(0.2),
                        ),
                        child: Ink(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFF6B6B), Color(0xFFFFD700)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            constraints: const BoxConstraints(minHeight: 50),
                            child: const Text(
                              'Apply Filters',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Profile Card and Buttons
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF6B6B),
                      ),
                    )
                  : _profiles.isEmpty || _currentIndex >= _profiles.length
                      ? const Center(
                          child: Text(
                            'No profiles found',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              color: Color(0xFF1A1A40),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: Card(
                                elevation: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: const BorderSide(
                                    color: Color(0xFFFF6B6B),
                                    width: 2,
                                  ),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFF8F1F1), Colors.white],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                        child: Container(
                                          height: 250,
                                          width: double.infinity,
                                          constraints: const BoxConstraints(
                                            minHeight: 250,
                                            maxHeight: 250,
                                          ),
                                          child: _profiles[_currentIndex].pfpPath == null
                                              ? Container(
                                                  decoration: const BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [Color(0xFFF8F1F1), Colors.white],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                  ),
                                                  child: const Center(
                                                    child: Text(
                                                      'No Profile Picture',
                                                      style: TextStyle(
                                                        fontFamily: 'Roboto',
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.w600,
                                                        color: Color(0xFF1A1A40),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : Image.network(
                                                  'http://localhost:3000/${_profiles[_currentIndex].pfpPath}',
                                                  height: 250,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return Container(
                                                      decoration: const BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [Color(0xFFF8F1F1), Colors.white],
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                        ),
                                                      ),
                                                      child: const Center(
                                                        child: CircularProgressIndicator(
                                                          color: Color(0xFFFF6B6B),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    decoration: const BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [Color(0xFFF8F1F1), Colors.white],
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                      ),
                                                    ),
                                                    child: const Center(
                                                      child: Text(
                                                        'No Profile Picture',
                                                        style: TextStyle(
                                                          fontFamily: 'Roboto',
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.w600,
                                                          color: Color(0xFF1A1A40),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: [
                                            Text(
                                              '${_profiles[_currentIndex].firstName ?? 'Unknown'} ${_profiles[_currentIndex].lastName ?? 'Unknown'}, ${_profiles[_currentIndex].age ?? 0}',
                                              style: const TextStyle(
                                                fontFamily: 'Roboto',
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1A1A40),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${_profiles[_currentIndex].city ?? 'Unknown'}, ${_profiles[_currentIndex].region ?? 'Unknown'}',
                                              style: const TextStyle(
                                                fontFamily: 'Roboto',
                                                fontSize: 16,
                                                color: Color(0xFF1A1A40),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _profiles[_currentIndex].bio ?? 'No bio',
                                              style: const TextStyle(
                                                fontFamily: 'Roboto',
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () => _handleButtonSwipe(false), // Left swipe
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Color(0xFFFF8787),
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _handleButtonSwipe(true), // Right swipe
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.favorite,
                                        color: Color(0xFFFF6B6B),
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}