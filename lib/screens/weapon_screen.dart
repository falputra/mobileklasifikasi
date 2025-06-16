import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'weapon_detail_screen.dart';
import 'add_weapon_screen.dart';
import 'edit_weapon_screen.dart';
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
    // Disabled sample data initialization for Firebase version
    // _weaponService.initializeSampleData();

    // TAMBAHKAN INI SEMENTARA UNTUK CLEANUP (HAPUS SETELAH TESTING):
    // _cleanupData();
  }

  // Method untuk cleanup data (hapus setelah testing berhasil)
  Future<void> _cleanupData() async {
    try {
      print('🔄 Cleaning up all weapons data...');
      await _weaponService.deleteAllWeapons();
      print('✅ All weapons data cleaned up');
    } catch (e) {
      print('❌ Error cleaning up data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff021024),
      body: Column(
        children: [
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

          SizedBox(height: 15),

          // Weapons list from Firebase
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _weaponService.getWeapons(),
              builder: (context, snapshot) {
                // Debug print
                print('🔍 StreamBuilder state: ${snapshot.connectionState}');
                print('🔍 Has error: ${snapshot.hasError}');
                print('🔍 Error: ${snapshot.error}');
                print('🔍 Data length: ${snapshot.data?.length ?? 0}');

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7DA0CA)),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading weapons...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
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
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Refresh
                          },
                          child: Text('Retry'),
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

  // Widget for individual weapon card - with proper image handling
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
            // Weapon image with proper network/asset handling
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Color(0xFF0a3067),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildWeaponImage(weapon['image'], weapon['imageType']),
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

                  // Action buttons
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

  // Helper method to build weapon image with local storage support
  Widget _buildWeaponImage(String? imageData, String? imageType) {
    // If no image data or empty, show placeholder
    if (imageData == null || imageData.isEmpty) {
      return Container(
        color: Color(0xFF0a3067),
        child: Icon(
          Icons.inventory_2_outlined,
          color: Colors.white54,
          size: 40,
        ),
      );
    }

    // Check if it's local storage image
    if (imageType == 'local') {
      return FutureBuilder<File?>(
        future: _getLocalImageFile(imageData),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: Color(0xFF0a3067),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7DA0CA)),
                    strokeWidth: 2,
                  ),
                ),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return Image.file(
              snapshot.data!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading local image: $error');
                return Container(
                  color: Color(0xFF0a3067),
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 40,
                  ),
                );
              },
            );
          } else {
            // File not found or error
            return Container(
              color: Color(0xFF0a3067),
              child: Icon(
                Icons.image_not_supported,
                color: Colors.white54,
                size: 40,
              ),
            );
          }
        },
      );
    }

    // Check if it's Base64 image
    if (imageType == 'base64') {
      try {
        final bytes = base64Decode(imageData);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading Base64 image: $error');
            return Container(
              color: Color(0xFF0a3067),
              child: Icon(
                Icons.broken_image,
                color: Colors.white54,
                size: 40,
              ),
            );
          },
        );
      } catch (e) {
        print('Error decoding Base64 image: $e');
        return Container(
          color: Color(0xFF0a3067),
          child: Icon(
            Icons.broken_image,
            color: Colors.white54,
            size: 40,
          ),
        );
      }
    }

    // Check if it's a network URL (from Firebase Storage)
    if (imageData.startsWith('http')) {
      return Image.network(
        imageData,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7DA0CA)),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading network image: $error');
          return Container(
            color: Color(0xFF0a3067),
            child: Icon(
              Icons.broken_image,
              color: Colors.white54,
              size: 40,
            ),
          );
        },
      );
    } else {
      // Fallback to asset image (for old data or local images)
      return Image.asset(
        imageData,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading asset image: $error');
          return Container(
            color: Color(0xFF0a3067),
            child: Icon(
              Icons.image_not_supported,
              color: Colors.white54,
              size: 40,
            ),
          );
        },
      );
    }
  }

  // Get local image file from relative path
  Future<File?> _getLocalImageFile(String relativePath) async {
    try {
      // Try app documents directory first
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        final fullPath = '${appDocDir.path}/$relativePath';
        final file = File(fullPath);

        if (await file.exists()) {
          print('✅ Local image found in app documents: $fullPath');
          return file;
        }
      } catch (e) {
        print('⚠️ Error accessing app documents directory: $e');
      }

      // Fallback: try temporary directory
      try {
        final tempDir = await getTemporaryDirectory();
        final fullPath = '${tempDir.path}/$relativePath';
        final file = File(fullPath);

        if (await file.exists()) {
          print('✅ Local image found in temp directory: $fullPath');
          return file;
        }
      } catch (e) {
        print('⚠️ Error accessing temp directory: $e');
      }

      print('❌ Local image not found: $relativePath');
      return null;
    } catch (e) {
      print('❌ Error getting local image: $e');
      return null;
    }
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