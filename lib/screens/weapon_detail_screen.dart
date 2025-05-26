import 'package:flutter/material.dart';

class WeaponDetailScreen extends StatelessWidget {
  final Map<String, dynamic> weapon;

  WeaponDetailScreen({required this.weapon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF021024),
      appBar: AppBar(
        backgroundColor: Color(0xFF052659),
        title: Text(
          weapon['name'] ?? 'Detail Senjata',
          style: TextStyle(
            fontFamily: 'OpenSans',
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weapon image
            Container(
              width: double.infinity,
              height: 300,
              color: Color(0xFF052659),
              child: Image.asset(
                weapon['image'] ?? 'images/placeholder.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.white70,
                      size: 80,
                    ),
                  );
                },
              ),
            ),

            // Weapon info
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weapon name
                  Text(
                    weapon['name'] ?? 'Unknown Weapon',
                    style: TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 10),

                  // Origin with icon
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF7DA0CA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.place,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 5),
                        Text(
                          weapon['origin'] ?? 'Unknown Origin',
                          style: TextStyle(
                            fontFamily: 'OpenSans',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // Description section
                  _buildInfoSection(
                    title: 'Deskripsi',
                    content: weapon['description'] ?? 'Tidak ada deskripsi',
                    icon: Icons.description,
                  ),

                  SizedBox(height: 25),

                  // Usage section
                  _buildInfoSection(
                    title: 'Kegunaan',
                    content: weapon['usage'] ?? 'Tidak ada informasi kegunaan',
                    icon: Icons.build,
                  ),

                  SizedBox(height: 30),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to edit screen
                            _showEditDialog(context);
                          },
                          icon: Icon(Icons.edit, size: 20),
                          label: Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF7DA0CA),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Share functionality
                            _showShareDialog(context);
                          },
                          icon: Icon(Icons.share, size: 20),
                          label: Text('Share'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xFF7DA0CA),
                            side: BorderSide(color: Color(0xFF7DA0CA)),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Color(0xFF7DA0CA),
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF052659),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFF7DA0CA).withOpacity(0.3)),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.justify,
          ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF052659),
          title: Text(
            'Edit Senjata',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Fitur edit akan segera tersedia!',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: TextStyle(color: Color(0xFF7DA0CA))),
            ),
          ],
        );
      },
    );
  }

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF052659),
          title: Text(
            'Bagikan Senjata',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bagikan informasi tentang ${weapon['name']}:',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF021024),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${weapon['name']} - Senjata tradisional dari ${weapon['origin']}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fitur share akan segera tersedia!'),
                    backgroundColor: Color(0xFF7DA0CA),
                  ),
                );
              },
              child: Text('Bagikan', style: TextStyle(color: Color(0xFF7DA0CA))),
            ),
          ],
        );
      },
    );
  }
}