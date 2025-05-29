import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
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

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _weaponService.searchWeapons(query.trim()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7DA0CA)),
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

        return Container(
          color: Color(0xFF021024),
          child: ListView.builder(
            padding: EdgeInsets.all(20),
            itemCount: weapons.length,
            itemBuilder: (context, index) {
              return _buildSearchResultCard(context, weapons[index]);
            },
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return Container(
        color: Color(0xFF021024),
        child: Column(
          children: [
            SizedBox(height: 40),
            SizedBox(height: 30),
          ],
        ),
      );
    }

    // Show real-time search results as user types
    return buildResults(context);
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
            child: weapon['image'] != null
                ? Image.network(
              weapon['image'],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.image_not_supported,
                  color: Colors.white54,
                  size: 30,
                );
              },
            )
                : Icon(
              Icons.security,
              color: Colors.white54,
              size: 30,
            ),
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

  Widget _buildTipItem(String title, String subtitle) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Color(0xFF7DA0CA),
              shape: BoxShape.circle,
            ),
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
                  subtitle,
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
}