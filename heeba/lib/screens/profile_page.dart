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

class _ProfilePageState extends State<ProfilePage> {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors.white, // Ensure visibility
              size: 30, // Increase size for better visibility
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _isEditing
            ? Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                      validator: (value) => value!.isEmpty ? 'First name is required' : null,
                    ),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      validator: (value) => value!.isEmpty ? 'Last name is required' : null,
                    ),
                    TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(labelText: 'Nickname (optional)'),
                    ),
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) return 'Age is required';
                        final age = int.tryParse(value);
                        if (age == null || age < 18) return 'Enter a valid age (18+)';
                        return null;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: ['Male', 'Female']
                          .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                          .toList(),
                      onChanged: (value) => setState(() => _gender = value),
                      validator: (value) => value == null ? 'Gender is required' : null,
                    ),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(labelText: 'Bio (optional)'),
                      maxLines: 3,
                    ),
                    DropdownButtonFormField<String>(
                      value: _region,
                      decoration: const InputDecoration(labelText: 'Region'),
                      items: _regionCities.keys
                          .map((region) => DropdownMenuItem(value: region, child: Text(region)))
                          .toList(),
                      onChanged: (value) => setState(() {
                        _region = value;
                        _city = null;
                      }),
                      validator: (value) => value == null ? 'Region is required' : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: _city,
                      decoration: const InputDecoration(labelText: 'City'),
                      items: _region == null
                          ? []
                          : _regionCities[_region]!
                              .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                              .toList(),
                      onChanged: (value) => setState(() => _city = value),
                      validator: (value) => value == null ? 'City is required' : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _pfp == null ? _pickPfp : null,
                      child: Text(_pfp == null ? 'Upload Profile Picture (optional)' : 'Image Selected'),
                    ),
                    if (_pfp != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Selected: ${_pfp!.name}'),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateProfile,
                      child: const Text('Save Profile'),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => _isEditing = false),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  _profile!.pfpPath == null
                      ? Container(
                          height: 200,
                          width: 200,
                          color: Colors.grey[300],
                          child: const Center(child: Text('No PFP')),
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
                            child: const Center(child: Text('No PFP')),
                          ),
                        ),
                  const SizedBox(height: 16),
                  Text(
                    '${_profile!.firstName} ${_profile!.lastName}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text('Age: ${_profile!.age}'),
                  Text('Gender: ${_profile!.gender ?? 'N/A'}'),
                  Text('Nickname: ${_profile!.nickname ?? 'N/A'}'),
                  Text('Location: ${_profile!.city}, ${_profile!.region}'),
                  Text('Bio: ${_profile!.bio ?? 'No bio'}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => setState(() => _isEditing = true),
                    child: const Text('Edit Profile'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                    child: const Text('Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300], // Optional: Make the button stand out with a different color
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}