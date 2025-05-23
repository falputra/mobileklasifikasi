import 'package:flutter/material.dart';
import '../../widgets/custom_navbar.dart';
import 'home_screen.dart';
import 'weapon_screen.dart';
import 'profile_screen.dart';

class MainPage extends StatefulWidget {
  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  final List<Widget> pages = [
    HomeScreen(),
    WeaponScreen(),
    ProfileScreen(),
  ];

  int selectedIndex = 0;

  void onTap(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff021024),
      body: Stack(
        children: [
          pages[selectedIndex],
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
    );
  }
}
