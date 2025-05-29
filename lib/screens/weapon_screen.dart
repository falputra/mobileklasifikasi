import 'package:flutter/material.dart';
import 'weapon_detail_screen.dart';
import 'add_weapon_screen.dart';
import 'edit_weapon_screen.dart'; // Import screen edit yang baru
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
          // Kurangi jarak atas dari 50 menjadi 20
          SizedBox(height: 20),

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

          // Kurangi jarak dari 30 menjadi 15
          SizedBox(height: 15),

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

                // Vertical scrolling weapon list
                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  itemCount: weapons.length,
                  itemBuilder: (context, index) {
                    return _buildWeaponCard(context, weapons[index], index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget for individual weapon card - modified with edit button
  Widget _buildWeaponCard(BuildContext context, Map<String, dynamic> weapon, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Color(0xFF052659),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Row(
          children: [
            // Weapon image
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Color(0xFF0a3067),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  weapon['image'] ?? 'images/placeholder.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.image_not_supported,
                      color: Colors.white54,
                      size: 40,
                    );
                  },
                ),
              ),
            ),

            SizedBox(width: 15),

            // Weapon details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weapon name
                  Text(
                    weapon['name'] ?? 'Unknown',
                    style: TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 8),

                  // Weapon origin (if available)
                  if (weapon['origin'] != null)
                    Text(
                      weapon['origin'],
                      style: TextStyle(
                        fontFamily: 'OpenSans',
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),

                  SizedBox(height: 15),

                  // Action buttons - now with 3 buttons
                  Row(
                    children: [
                      // Detail button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WeaponDetailScreen(weapon: weapon),
                              ),
                            );
                          },
                          child: Text(
                            'Detail',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF7DA0CA),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8),
                            minimumSize: Size(0, 32),
                          ),
                        ),
                      ),

                      SizedBox(width: 8),

                      // Edit button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditWeaponScreen(weapon: weapon),
                              ),
                            );
                          },
                          child: Text(
                            'Edit',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8),
                            minimumSize: Size(0, 32),
                          ),
                        ),
                      ),

                      SizedBox(width: 8),

                      // Delete button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          onPressed: () => _showDeleteDialog(weapon),
                          icon: Icon(Icons.delete, color: Colors.red, size: 18),
                          constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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