import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'services/weapon_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp();

    // Initialize sample data (hanya jika belum ada data)
    final weaponService = WeaponService();
    await weaponService.initializeSampleData();

    runApp(MyApp());
  } catch (e) {
    print('Error initializing app: $e');
    // Tetap jalankan app meskipun ada error
    runApp(MyApp());
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klasifikasi Senjata Tradisional Jawa Barat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'OpenSans',
        scaffoldBackgroundColor: Color(0xFF021024),
        // Tambahan theme untuk konsistensi
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF021024),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
        ),
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}