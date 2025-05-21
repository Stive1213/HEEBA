import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
import '../services/api_service.dart';

class MatchPage extends StatefulWidget {
  const MatchPage({super.key});

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  List<Map<String, dynamic>> _matches = []; // Store match_id and profile
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    setState(() => _isLoading = true);
    try {
      final matchesJson = await Provider.of<ApiService>(context, listen: false).fetchMatches();
      setState(() {
        _matches = matchesJson.map((match) => {
          'match_id': match['match_id'],
          'profile': match['profile'], // Use the already-parsed Profile object
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load matches: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEC407A), Color(0xFFF06292)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEC407A)))
          : _matches.isEmpty
              ? const Center(child: Text('No matches yet', style: TextStyle(color: Color(0xFF1B263B))))
              : ListView.builder(
                  itemCount: _matches.length,
                  itemBuilder: (context, index) {
                    final matchData = _matches[index];
                    final matchId = matchData['match_id'];
                    final match = matchData['profile'] as Profile;
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: const Color(0xFFFFFFFF),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: match.pfpPath == null
                            ? Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[300],
                                child: const Center(child: Text('No PFP')),
                              )
                            : Image.network(
                                'http://localhost:3000${match.pfpPath}',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[300],
                                  child: const Center(child: Text('No PFP')),
                                ),
                              ),
                        title: Text(
                          '${match.firstName} ${match.lastName}',
                          style: const TextStyle(color: Color(0xFF1B263B)),
                        ),
                        subtitle: Text(
                          '${match.city}, ${match.region}',
                          style: const TextStyle(color: Color(0x666666)),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/chat',
                              arguments: {
                                'matchId': matchId,
                                'matchName': '${match.firstName} ${match.lastName}',
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 6,
                            shadowColor: Colors.black.withOpacity(0.3),
                          ),
                          child: Ink(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFEC407A), Color(0xFFEF9A9A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                              child: Text(
                                'Chat',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}