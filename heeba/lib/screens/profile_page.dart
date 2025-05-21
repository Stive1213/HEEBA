import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/profile.dart';
import '../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  Profile? _profile;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();
  String? _gender;
  String? _region;
  String? _city;
  PlatformFile? _pfp;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _heartScaleAnimation;
  late Animation<double> _heartOpacityAnimation;

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
    'South West Ethiopia Peoples\' Region': ['Bonga'],
    'Harari': ['Harar'],
    'Central Ethiopia Region': ['Bishoftu'],
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _heartScaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _heartOpacityAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await Provider.of<ApiService>(context, listen: false).getCurrentProfile();
      setState(() {
        _profile = profile;
        _firstNameController.text = profile.firstName;
        _lastNameController.text = profile.lastName;
        _nicknameController.text = profile.nickname ?? '';
        _ageController.text = profile.age.toString();
        _gender = profile.gender;
        _bioController.text = profile.bio ?? '';
        _region = profile.region;
        _city = profile.city;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await Provider.of<ApiService>(context, listen: false).saveProfile(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          nickname: _nicknameController.text.isEmpty ? null : _nicknameController.text,
          age: int.parse(_ageController.text),
          gender: _gender,
          bio: _bioController.text.isEmpty ? null : _bioController.text,
          region: _region!,
          city: _city!,
          pfp: _pfp,
        );
        setState(() {
          _isEditing = false;
          _pfp = null;
        });
        _loadProfile();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickPfp() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() => _pfp = result.files.first);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _animationController.dispose();
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
                fontSize: 24,
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
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _heartScaleAnimation.value,
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 24,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              const Text(
                'My Profile',
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
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFF8787)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.settings,
                color: Colors.white,
                size: 30,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
        body: _isLoading || _profile == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF6B6B),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: _isEditing
                    ? Form(
                        key: _formKey,
                        child: Column(
                          children: [
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
                              child: TextFormField(
                                controller: _firstNameController,
                                decoration: const InputDecoration(
                                  labelText: 'First Name',
                                  prefixIcon: Icon(Icons.person, color: Color(0xFFFF6B6B)),
                                ),
                                validator: (value) => value!.isEmpty ? 'First name is required' : null,
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
                              child: TextFormField(
                                controller: _lastNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Last Name',
                                  prefixIcon: Icon(Icons.person, color: Color(0xFFFF6B6B)),
                                ),
                                validator: (value) => value!.isEmpty ? 'Last name is required' : null,
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
                              child: TextFormField(
                                controller: _nicknameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nickname (optional)',
                                  prefixIcon: Icon(Icons.edit, color: Color(0xFFFF6B6B)),
                                ),
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
                              child: TextFormField(
                                controller: _ageController,
                                decoration: const InputDecoration(
                                  labelText: 'Age',
                                  prefixIcon: Icon(Icons.cake, color: Color(0xFFFF6B6B)),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value!.isEmpty) return 'Age is required';
                                  final age = int.tryParse(value);
                                  if (age == null || age < 18) return 'Enter a valid age (18+)';
                                  return null;
                                },
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
                                value: _gender,
                                decoration: const InputDecoration(
                                  labelText: 'Gender',
                                  prefixIcon: Icon(Icons.person_outline, color: Color(0xFFFF6B6B)),
                                ),
                                items: ['Male', 'Female']
                                    .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                                    .toList(),
                                onChanged: (value) => setState(() => _gender = value),
                                validator: (value) => value == null ? 'Gender is required' : null,
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
                              child: TextFormField(
                                controller: _bioController,
                                decoration: const InputDecoration(
                                  labelText: 'Bio (optional)',
                                  prefixIcon: Icon(Icons.description, color: Color(0xFFFF6B6B)),
                                ),
                                maxLines: 3,
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
                                value: _region,
                                decoration: const InputDecoration(
                                  labelText: 'Region',
                                  prefixIcon: Icon(Icons.location_on, color: Color(0xFFFF6B6B)),
                                ),
                                items: _regionCities.keys
                                    .map((region) => DropdownMenuItem(value: region, child: Text(region)))
                                    .toList(),
                                onChanged: (value) => setState(() {
                                  _region = value;
                                  _city = null;
                                }),
                                validator: (value) => value == null ? 'Region is required' : null,
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
                                        .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                                        .toList(),
                                onChanged: (value) => setState(() => _city = value),
                                validator: (value) => value == null ? 'City is required' : null,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _pfp == null ? _pickPfp : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
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
                                  child: Text(
                                    _pfp == null ? 'Upload Profile Picture (optional)' : 'Image Selected',
                                    style: const TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_pfp != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Text(
                                  'Selected: ${_pfp!.name}',
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 14,
                                    color: Color(0xFF1A1A40),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
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
                                    'Save Profile',
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
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => setState(() => _isEditing = false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFFF6B6B),
                                side: const BorderSide(color: Color(0xFFFF6B6B)),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFFF6B6B),
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _profile!.pfpPath == null
                                      ? Container(
                                          height: 200,
                                          width: 200,
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Text(
                                              'No PFP',
                                              style: TextStyle(
                                                fontFamily: 'Roboto',
                                                fontSize: 16,
                                                color: Color(0xFF1A1A40),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Image.network(
                                          'http://localhost:3000/${_profile!.pfpPath}',
                                          height: 200,
                                          width: 200,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            height: 200,
                                            width: 200,
                                            color: Colors.grey[300],
                                            child: const Center(
                                              child: Text(
                                                'No PFP',
                                                style: TextStyle(
                                                  fontFamily: 'Roboto',
                                                  fontSize: 16,
                                                  color: Color(0xFF1A1A40),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _heartOpacityAnimation.value,
                                      child: Transform.scale(
                                        scale: _heartScaleAnimation.value,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black,
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.favorite,
                                            color: Color(0xFFFF6B6B),
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${_profile!.firstName} ${_profile!.lastName}',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A40),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Age: ${_profile!.age}',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              color: Color(0xFF1A1A40),
                            ),
                          ),
                          Text(
                            'Gender: ${_profile!.gender ?? 'N/A'}',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              color: Color(0xFF1A1A40),
                            ),
                          ),
                          Text(
                            'Nickname: ${_profile!.nickname ?? 'N/A'}',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              color: Color(0xFF1A1A40),
                            ),
                          ),
                          Text(
                            'Location: ${_profile!.city}, ${_profile!.region}',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              color: Color(0xFF1A1A40),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bio: ${_profile!.bio ?? 'No bio'}',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              color: Colors.grey,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => setState(() => _isEditing = true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
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
                                  'Edit Profile',
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
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/settings');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFFFF6B6B),
                              side: const BorderSide(color: Color(0xFFFF6B6B)),
                            ),
                            child: const Text('Settings'),
                          ),
                        ],
                      ),
              ),
      ),
    );
  }
}