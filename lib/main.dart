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
    print('🎬 AuthWrapper initState - Starting splash screen...');
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      print('⏰ Splash screen showing - waiting 3 seconds...');

      // TAMBAHKAN DELAY UNTUK SPLASH SCREEN - INI YANG PENTING!
      await Future.delayed(Duration(seconds: 3));

      print('🔄 Splash screen finished - checking auth...');

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

      print('✅ Auth check completed - navigating to next screen');

    } catch (e) {
      print('❌ Error checking auth state: $e');
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 AuthWrapper build - _isLoading: $_isLoading');

    if (_isLoading) {
      print('📱 Showing SplashScreen');
      return SplashScreen();
    }

    if (_isLoggedIn) {
      print('🏠 Navigating to MainPage');
      return MainPage();
    } else {
      print('🔐 Navigating to LoginScreen');
      return LoginScreen();
    }
  }
}