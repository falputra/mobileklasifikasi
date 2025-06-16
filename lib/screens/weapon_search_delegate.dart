import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../services/weapon_service.dart';
import 'weapon_detail_screen.dart';

class WeaponSearchDelegate extends SearchDelegate {
  final WeaponService _weaponService = WeaponService();

  @override
  String get searchFieldLabel => 'Cari nama senjata atau lokasi...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF052659),
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 56,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.normal,
        ),
      ),
      // Fix untuk search field
      scaffoldBackgroundColor: Color(0xFF052659),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear, color: Colors.white),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return _buildEmptyState('Masukkan kata kunci pencarian');
    }

    return Container(
      color: Color(0xFF021024),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _weaponService.searchWeapons(query.trim()),
        builder: (context, snapshot) {
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
                    'Mencari "$query"...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState('Error: ${snapshot.error}');
          }

          final weapons = snapshot.data ?? [];

          if (weapons.isEmpty) {
            return _buildEmptyState('Tidak ditemukan senjata dengan kata kunci "$query"');
          }

          return ListView.builder(
            padding: EdgeInsets.all(20),
            itemCount: weapons.length,
            itemBuilder: (context, index) {
              return _buildSearchResultCard(context, weapons[index]);
            },
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return Container(
        color: Color(0xFF021024),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  color: Colors.white54,
                  size: 80,
                ),
                SizedBox(height: 20),
                Text(
                  'Cari Senjata Tradisional',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'OpenSans',
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Ketik nama senjata atau asal daerah',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF052659).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Tips Pencarian:',
                        style: TextStyle(
                          color: Color(0xFF7DA0CA),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildSearchTip('🔍', 'Cari berdasarkan nama', 'Contoh: "Kujang", "Golok"'),
                      _buildSearchTip('📍', 'Cari berdasarkan daerah', 'Contoh: "Jawa Barat", "Sunda"'),
                      _buildSearchTip('📝', 'Cari berdasarkan deskripsi', 'Kata kunci dalam deskripsi'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show real-time search results as user types
    return buildResults(context);
  }

  Widget _buildSearchTip(String emoji, String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build weapon image with Base64 support
  Widget _buildWeaponImage(String? imageData, String? imageType) {
    // If no image data or empty, show placeholder
    if (imageData == null || imageData.isEmpty) {
      return Container(
        color: Color(0xFF0a3067),
        child: Icon(
          Icons.inventory_2_outlined,
          color: Colors.white54,
          size: 30,
        ),
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
                size: 30,
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
            size: 30,
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
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7DA0CA)),
                strokeWidth: 2,
              ),
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
              size: 30,
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
              size: 30,
            ),
          );
        },
      );
    }
  }

  Widget _buildSearchResultCard(BuildContext context, Map<String, dynamic> weapon) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Color(0xFF052659),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Color(0xFF7DA0CA).withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(15),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Color(0xFF0a3067),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildWeaponImage(weapon['image'], weapon['imageType']),
          ),
        ),
        title: Text(
          weapon['name'] ?? 'Unknown',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.place, color: Color(0xFF7DA0CA), size: 16),
                SizedBox(width: 5),
                Text(
                  weapon['origin'] ?? 'Unknown',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (weapon['description'] != null) ...[
              SizedBox(height: 8),
              Text(
                weapon['description'].length > 100
                    ? '${weapon['description'].substring(0, 100)}...'
                    : weapon['description'],
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: Color(0xFF7DA0CA),
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            onPressed: () {
              close(context, null);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WeaponDetailScreen(weapon: weapon),
                ),
              );
            },
          ),
        ),
        onTap: () {
          close(context, null);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WeaponDetailScreen(weapon: weapon),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      color: Color(0xFF021024),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: Colors.white54,
              size: 80,
            ),
            SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Coba kata kunci lain atau periksa ejaan',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      color: Color(0xFF021024),
      child: Center(
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
              error,
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}