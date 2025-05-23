import 'package:flutter/material.dart';
import 'nav_item.dart';

class CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  CustomNavBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    print('CustomNavBar build - selectedIndex: $selectedIndex'); // Debug print
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 80,
        decoration: BoxDecoration(
          color: Color(0xff052659),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            NavItem(
              icon: Icons.home, 
              label: 'Home', 
              index: 0, 
              selectedIndex: selectedIndex, 
              onTap: (int index) {
                print('Home NavItem tapped: $index'); // Debug print
                onTap(index);
              }
            ),
            NavItem(
              icon: Icons.gavel, 
              label: 'Weapon', 
              index: 1, 
              selectedIndex: selectedIndex, 
              onTap: (int index) {
                print('Weapon NavItem tapped: $index'); // Debug print
                onTap(index);
              }
            ),
            NavItem(
              icon: Icons.person,
              label: 'Profile', 
              index: 2, 
              selectedIndex: selectedIndex, 
              onTap: (int index) {
                print('Profile NavItem tapped: $index'); // Debug print
                onTap(index);
              }
            ),
          ],
        ),
      ),
    );
  }
}