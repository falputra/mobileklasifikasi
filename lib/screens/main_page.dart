import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'weapon_screen.dart';
import 'profile_screen.dart';
import 'users_screen.dart';
import '../services/firestore_auth_service.dart';
import 'login_screen.dart';

class MainPage extends StatefulWidget {
  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  final FirestoreAuthService _authService = FirestoreAuthService();

  final List<Widget> pages = [
    HomeScreen(),
    WeaponScreen(),
    UsersScreen(),
    ProfileScreen(),
  ];

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    // PERBAIKAN: FirestoreAuthService tidak punya authStateChanges
    // Gunakan periodic check atau hapus method ini
    // Untuk sementara, kita comment dulu

    // _authService.authStateChanges.listen((user) {
    //   if (user == null && mounted) {
    //     Navigator.of(context).pushAndRemoveUntil(
    //       MaterialPageRoute(builder: (context) => LoginScreen()),
    //           (route) => false,
    //     );
    //   }
    // });
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
        child: Column(
          children: [
            // Halaman konten - menggunakan Expanded agar mengisi ruang yang tersisa
            Expanded(
              child: IndexedStack(
                index: selectedIndex,
                children: pages,
              ),
            ),
            // Navigation bar di bawah - menempel langsung tanpa margin
            CustomNavBar(
              currentIndex: selectedIndex,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Navigation Bar Widget - Dihilangkan shadow dan rounded corner
class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      width: double.infinity, // Mengisi lebar penuh
      decoration: BoxDecoration(
        color: Color(0xFF052659),
        // Hilangkan borderRadius agar menempel sempurna ke bawah
        // borderRadius: BorderRadius.only(
        //   topLeft: Radius.circular(20),
        //   topRight: Radius.circular(20),
        // ),
        // Hilangkan shadow agar tidak menganggu
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black26,
        //     blurRadius: 10,
        //     offset: Offset(0, -2),
        //   ),
        // ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.home,
            label: 'Home',
            index: 0,
            isSelected: currentIndex == 0,
          ),
          _buildNavItem(
            icon: Icons.add_circle_outline,
            label: 'Add Weapon',
            index: 1,
            isSelected: currentIndex == 1,
          ),
          _buildNavItem(
            icon: Icons.people,
            label: 'Users',
            index: 2,
            isSelected: currentIndex == 2,
          ),
          _buildNavItem(
            icon: Icons.person,
            label: 'Profile',
            index: 3,
            isSelected: currentIndex == 3,
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
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF7DA0CA) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}