import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _gender;
  String? _region;
  String? _city;
  final _bioController = TextEditingController();
  PlatformFile? _pfpFile;
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

  Future<void> _pickPfp() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pfpFile = result.files.single;
      });
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.saveProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        age: int.parse(_ageController.text),
        gender: _gender,
        region: _region!,
        city: _city!,
        bio: _bioController.text.isNotEmpty ? _bioController.text : null,
        pfp: _pfpFile,
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: ${e.toString().replaceAll('Exception: ', '')}'),
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _firstNameController,
                          decoration: inputDecoration.copyWith(labelText: 'First Name'),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Enter first name' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: inputDecoration.copyWith(labelText: 'Last Name'),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Enter last name' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _ageController,
                          decoration: inputDecoration.copyWith(labelText: 'Age'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter age';
                            final age = int.tryParse(value);
                            if (age == null || age < 18) return 'Must be 18+';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _gender,
                          decoration: inputDecoration.copyWith(labelText: 'Gender'),
                          items: ['Male', 'Female']
                              .map((gender) => DropdownMenuItem(
                                    value: gender,
                                    child: Text(gender),
                                  ))
                              .toList(),
                          onChanged: (value) => setState(() => _gender = value),
                          validator: (value) => value == null ? 'Select gender' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _region,
                          decoration: inputDecoration.copyWith(labelText: 'Region'),
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
                          validator: (value) => value == null ? 'Select region' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _city,
                          decoration: inputDecoration.copyWith(labelText: 'City'),
                          items: _region == null
                              ? []
                              : _regionCities[_region]!
                                  .map((city) => DropdownMenuItem(
                                        value: city,
                                        child: Text(city),
                                      ))
                                  .toList(),
                          onChanged: (value) => setState(() => _city = value),
                          validator: (value) => value == null ? 'Select city' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _bioController,
                          decoration: inputDecoration.copyWith(labelText: 'Bio (optional)'),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: _pickPfp,
                          icon: const Icon(Icons.upload),
                          label: const Text('Upload Profile Picture'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          ),
                        ),
                        if (_pfpFile != null) ...[
                          const SizedBox(height: 8),
                          Text('Selected: ${_pfpFile!.name}',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _submitProfile,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Save Profile', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
