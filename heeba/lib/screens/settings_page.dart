import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'auth_screen.dart'; // Navigate to AuthScreen after logout/delete

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    try {
      final profile = await Provider.of<ApiService>(context, listen: false).getCurrentProfile();
      setState(() {
        _notificationsEnabled = profile.notificationsEnabled;
      });
    } catch (e) {
      if (_notificationsEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notification preference: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    try {
      await Provider.of<ApiService>(context, listen: false).updateNotificationPreference(value);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification preference updated')),
      );
    } catch (e) {
      setState(() {
        _notificationsEnabled = !value; // Revert on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update notification preference: ${e.toString()}')),
      );
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Provider.of<ApiService>(context, listen: false).changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change password: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await Provider.of<ApiService>(context, listen: false).clearToken();
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/auth',
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await Provider.of<ApiService>(context, listen: false).deleteAccount();
      await Provider.of<ApiService>(context, listen: false).clearToken();
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/auth',
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // Notification Toggle
                  SwitchListTile(
                    title: const Text('Enable Notifications'),
                    subtitle: const Text('Receive alerts for new messages'),
                    value: _notificationsEnabled,
                    onChanged: _toggleNotifications,
                  ),
                  const Divider(),
                  // Change Password
                  const Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _currentPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _changePassword,
                    child: const Text('Change Password'),
                  ),
                  const Divider(),
                  // Log Out and Delete Account
                  ListTile(
                    title: const Text('Log Out', style: TextStyle(color: Colors.blue)),
                    onTap: _logout,
                  ),
                  ListTile(
                    title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                    onTap: _deleteAccount,
                  ),
                ],
              ),
            ),
    );
  }
}