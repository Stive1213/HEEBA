import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/home_page.dart';
import 'screens/profile_page.dart';
import 'screens/match_page.dart';
import 'screens/chat_page.dart';
import 'screens/settings_page.dart'; // Import the new SettingsPage

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ApiService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Dating App',
        theme: ThemeData(
          primarySwatch: Colors.purple,
        ),
        initialRoute: '/auth',
        routes: {
          '/auth': (context) => const AuthScreen(),
          '/profile-setup': (context) => const ProfileSetupScreen(),
          '/home': (context) => const MainScreen(),
          '/chat': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return ChatPage(
              matchId: args['matchId'],
              matchName: args['matchName'],
            );
          },
          '/settings': (context) => const SettingsPage(), // Add SettingsPage route
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _hasProfile = false;

  @override
  void initState() {
    super.initState();
    // Delay the provider call until after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfile();
    });
  }

  Future<void> _checkProfile() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final hasProfile = await apiService.checkProfile();
      if (!hasProfile) {
        Navigator.pushNamed(context, '/profile-setup');
      } else {
        setState(() {
          _hasProfile = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking profile: $e')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  static final List<Widget> _pages = [
    const HomePage(),
    const MatchPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_hasProfile) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.swipe), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Matches'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}