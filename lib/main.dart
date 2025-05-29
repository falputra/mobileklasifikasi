// main.dart - FIRESTORE AUTH VERSION LENGKAP
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_page.dart';
import 'services/firestore_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Error initializing Firebase: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klasifikasi Senjata Tradisional',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'OpenSans',
      ),
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final FirestoreAuthService _authService = FirestoreAuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      // Initialize auth service
      await _authService.initializeAuth();

      // Check if user is logged in
      final isLoggedIn = _authService.isLoggedIn;

      print('🔍 DEBUG - User logged in: $isLoggedIn');
      print('🔍 DEBUG - Current user ID: ${_authService.currentUserId}');

      setState(() {
        _isLoggedIn = isLoggedIn;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error checking auth state: $e');
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  // TAMBAHKAN BUILD METHOD INI:
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SplashScreen();
    }

    if (_isLoggedIn) {
      print('🔍 DEBUG - Showing MainPage');
      return MainPage();
    } else {
      print('🔍 DEBUG - Showing LoginScreen');
      return LoginScreen();
    }
  }
}