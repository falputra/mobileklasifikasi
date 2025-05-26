import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'weapon_screen.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class MainPage extends StatefulWidget {
  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  final AuthService _authService = AuthService();

  final List<Widget> pages = [
    HomeScreen(),
    WeaponScreen(),
    ProfileScreen(),
  ];

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      if (user == null && mounted) {
        // User is signed out, redirect to login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false,
        );
      }
    });
  }

  void onTap(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff021024),
      body: SafeArea(
        child: Stack(
          children: [
            // Halaman konten
            IndexedStack(
              index: selectedIndex,
              children: pages,
            ),
            // Navigation bar di bawah
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: CustomNavBar(
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Navigation Bar Widget
class CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFF052659),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            icon: Icons.home,
            label: 'Home',
            index: 0,
            isSelected: selectedIndex == 0,
          ),
          _buildNavItem(
            icon: Icons.security,
            label: 'Weapon',
            index: 1,
            isSelected: selectedIndex == 1,
          ),
          _buildNavItem(
            icon: Icons.person,
            label: 'Profile',
            index: 2,
            isSelected: selectedIndex == 2,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF7DA0CA) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            if (isSelected) ...[
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}