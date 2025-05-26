import 'package:flutter/material.dart';
import 'weapon_detail_screen.dart';
import 'add_weapon_screen.dart';
import '../services/weapon_service.dart';
import 'weapon_search_delegate.dart';

class WeaponScreen extends StatefulWidget {
  @override
  _WeaponScreenState createState() => _WeaponScreenState();
}

class _WeaponScreenState extends State<WeaponScreen> {
  final WeaponService _weaponService = WeaponService();

  @override
  void initState() {
    super.initState();
    // Initialize sample data on first run
    _weaponService.initializeSampleData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff021024),
      body: Column(
        children: [
          SizedBox(height: 50),

          // Top bar with title and action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weapon',
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    // Add weapon button
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF7DA0CA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.add, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddWeaponScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    // Search button
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF2D3748),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.search, color: Colors.white),
                        onPressed: () {
                          showSearch(
                            context: context,
                            delegate: WeaponSearchDelegate(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 30),

          // Weapons list from Firebase
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _weaponService.getWeapons(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7DA0CA)),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final weapons = snapshot.data ?? [];

                if (weapons.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.white54,
                          size: 80,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada senjata',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Klik tombol + untuk menambah senjata',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Horizontal scrolling weapon cards
                      Container(
                        height: 350,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          itemCount: weapons.length,
                          itemBuilder: (context, index) {
                            return _buildWeaponCard(context, weapons[index]);
                          },
                        ),
                      ),

                      SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget for individual weapon card
  Widget _buildWeaponCard(BuildContext context, Map<String, dynamic> weapon) {
    return Container(
      width: 180,
      margin: EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: Color(0xFF052659),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Weapon image
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              child: Container(
                width: double.infinity,
                color: Color(0xFF052659),
                child: Image.asset(
                  weapon['image'] ?? 'images/placeholder.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.image_not_supported,
                      color: Colors.white,
                      size: 50,
                    );
                  },
                ),
              ),
            ),
          ),

          // Weapon name
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              weapon['name'] ?? 'Unknown',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // See more button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WeaponDetailScreen(weapon: weapon),
                      ),
                    );
                  },
                  child: Text('Detail'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7DA0CA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    minimumSize: Size(60, 32),
                  ),
                ),

                // Delete button
                IconButton(
                  onPressed: () => _showDeleteDialog(weapon),
                  icon: Icon(Icons.delete, color: Colors.red, size: 20),
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> weapon) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF052659),
          title: Text(
            'Hapus Senjata',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus ${weapon['name']}?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _weaponService.deleteWeapon(weapon['id']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Senjata berhasil dihapus!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}