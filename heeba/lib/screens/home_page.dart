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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _minAgeController = TextEditingController(text: '18');
  final _maxAgeController = TextEditingController(text: '35');
  String? _region;
  String? _city;
  List<Profile> _profiles = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  Timer? _debounce;
  late AnimationController _animationController;
  late Animation<double> _heartScaleAnimation;

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _heartScaleAnimation = Tween<double>(begin: 0.9, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutSine),
    );
    _fetchProfiles();
  }

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
              backgroundColor: const Color(0xFFE57373),
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
              backgroundColor: const Color(0xFFE57373),
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
            backgroundColor: const Color(0xFFE57373),
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
  void dispose() {
    _minAgeController.dispose();
    _maxAgeController.dispose();
    _debounce?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: const Color(0xFFF06292), // Soft pink
        scaffoldBackgroundColor: const Color(0xFFF9F7F7), // Warm off-white
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            color: Color(0xFF1A1A40), // Deep navy
          ),
          labelMedium: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            color: Colors.grey,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A40),
          ),
          headlineSmall: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Color(0xFFF06292),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 6,
            shadowColor: Colors.black.withOpacity(0.3),
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
          contentPadding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF06292), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE57373), width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE57373), width: 2),
          ),
          labelStyle: const TextStyle(
            fontFamily: 'Roboto',
            color: Colors.grey,
            fontSize: 14,
          ),
          errorStyle: const TextStyle(
            fontFamily: 'Roboto',
            color: Color(0xFFE57373),
            fontSize: 12,
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _heartScaleAnimation.value,
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 26,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.95 + _heartScaleAnimation.value * 0.05,
                    child: const Text(
                      'HEEBA',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF06292), Color(0xFFF48FB1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    AppBar().preferredSize.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Filter Section
                  Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 20),
                                      child: TextFormField(
                                        controller: _minAgeController,
                                        decoration: InputDecoration(
                                          labelText: 'Min Age',
                                          prefixIcon: const Icon(Icons.person, color: Color(0xFFF06292)),
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
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
                                      margin: const EdgeInsets.only(bottom: 20),
                                      child: TextFormField(
                                        controller: _maxAgeController,
                                        decoration: InputDecoration(
                                          labelText: 'Max Age',
                                          prefixIcon: const Icon(Icons.person, color: Color(0xFFF06292)),
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
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
                                margin: const EdgeInsets.only(bottom: 20),
                                child: DropdownButtonFormField<String>(
                                  value: _region,
                                  decoration: InputDecoration(
                                    labelText: 'Region',
                                    prefixIcon: const Icon(Icons.location_on, color: Color(0xFFF06292)),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
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
                                margin: const EdgeInsets.only(bottom: 20),
                                child: DropdownButtonFormField<String>(
                                  value: _city,
                                  decoration: InputDecoration(
                                    labelText: 'City',
                                    prefixIcon: const Icon(Icons.location_city, color: Color(0xFFF06292)),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
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
                              const SizedBox(height: 20),
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      _fetchProfiles();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    elevation: 6,
                                    shadowColor: Colors.black.withOpacity(0.3),
                                  ),
                                  child: Ink(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFFF06292), Color(0xFFFF8A80)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.all(Radius.circular(25)),
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      constraints: const BoxConstraints(minHeight: 56),
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
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Profile Card and Buttons
                  Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFF06292),
                            ),
                          )
                        : _profiles.isEmpty || _currentIndex >= _profiles.length
                            ? Card(
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(
                                    child: Text(
                                      'No profiles found',
                                      style: TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 18,
                                        color: Color(0xFF1A1A40),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Card(
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFF9F7F7), Colors.white],
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
                                          height: MediaQuery.of(context).size.height * 0.4,
                                          width: double.infinity,
                                          child: _profiles[_currentIndex].pfpPath == null
                                              ? Container(
                                                  decoration: const BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [Color(0xFFF9F7F7), Colors.white],
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
                                                  height: MediaQuery.of(context).size.height * 0.4,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return Container(
                                                      decoration: const BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [Color(0xFFF9F7F7), Colors.white],
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                        ),
                                                      ),
                                                      child: const Center(
                                                        child: CircularProgressIndicator(
                                                          color: Color(0xFFF06292),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    decoration: const BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [Color(0xFFF9F7F7), Colors.white],
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
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          children: [
                                            Text(
                                              '${_profiles[_currentIndex].firstName ?? 'Unknown'} ${_profiles[_currentIndex].lastName ?? 'Unknown'}, ${_profiles[_currentIndex].age ?? 0}',
                                              style: const TextStyle(
                                                fontFamily: 'Roboto',
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1A1A40),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              '${_profiles[_currentIndex].city ?? 'Unknown'}, ${_profiles[_currentIndex].region ?? 'Unknown'}',
                                              style: const TextStyle(
                                                fontFamily: 'Roboto',
                                                fontSize: 16,
                                                color: Color(0xFF1A1A40),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 12),
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
                  const SizedBox(height: 24),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => _handleButtonSwipe(false), // Left swipe
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFFE57373), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Color(0xFFE57373),
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => _handleButtonSwipe(true), // Right swipe
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFFF06292), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _heartScaleAnimation.value,
                                    child: const Icon(
                                      Icons.favorite,
                                      color: Color(0xFFF06292),
                                      size: 36,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24), // Extra space for bottom navigation bar
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}