import 'package:flutter/material.dart';
import 'weapon_detail_screen.dart';

class WeaponScreen extends StatelessWidget {
  // Sample weapon data - this could be replaced with your actual data later
  final List<Map<String, dynamic>> weapons = [
    {
      'name': 'Kujang',
      'image': 'images/kujang.png',
    },
    {
      'name': 'Bedog',
      'image': 'images/bedog.png',
    },
    {
      'name': 'Golok',
      'image': 'images/golok.jpg',
    },
    {
      'name': 'Patik',
      'image': 'images/patik.webp',
    },
    {
      'name': 'Congkrang',
      'image': 'images/congkrang.webp',
    },
    {
      'name': 'Ani-ani (Ketam)',
      'image': 'images/aniani.webp',
    },
     {
      'name': 'Sulimat',
      'image': 'images/sulimat.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff021024),
      body: Column(
        children: [
          SizedBox(height: 50),

          // Top bar with title and search icon
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
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF2D3748),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.search, color: Colors.white),
                    onPressed: () {
                      // Implement search functionality
                      showSearch(
                        context: context,
                        delegate: WeaponSearchDelegate(weapons),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 130),

          // Horizontal scrolling weapon cards
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // First row - horizontal scrolling cards
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

                  // Additional content can be added here if needed
                  SizedBox(height: 20),
                ],
              ),
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
                  weapon['image'],
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
              weapon['name'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          // "See more" button
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: ElevatedButton(
              onPressed: () {
                // Navigate to detailed weapon screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeaponDetailScreen(weapon: weapon),
                  ),
                );
              },
              child: Text('See more'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7DA0CA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Search functionality
class WeaponSearchDelegate extends SearchDelegate<String> {
  final List<Map<String, dynamic>> weapons;

  WeaponSearchDelegate(this.weapons);

  @override
  String get searchFieldLabel => 'Search Weapons';

  @override
  TextStyle get searchFieldStyle => TextStyle(
    color: Colors.white,
    fontSize: 18,
  );

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xff021024),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
      ),
      scaffoldBackgroundColor: Color(0xff021024),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = weapons
        .where((weapon) =>
        weapon['name'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Container(
      color: Color(0xff021024),
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final weapon = results[index];
          return ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: AssetImage(weapon['image']),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    // Handle image loading error
                  },
                ),
              ),
            ),
            title: Text(
              weapon['name'],
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WeaponDetailScreen(weapon: weapon),
                ),
              );
            },
          );
        },
      ),
    );
  }
}