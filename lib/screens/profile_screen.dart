// screens/profile_screen.dart - FIRESTORE VERSION
import 'package:flutter/material.dart';
import '../services/firestore_auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreAuthService _authService = FirestoreAuthService();
  Map<String, dynamic>? userData;
  bool _isLoading = true;

  // Data anggota tim yang sudah ada
  final List<Map<String, String>> members = [
    {"name": "Ali Abdurrahman Hakim", "id": "2307413015"},
    {"name": "Muhammad Hilmi Bilad", "id": "2307413022", "image": "images/WUKONGPC.png"},
    {"name": "Naufal Putra Hasan", "id": "2307413009"},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Get current user data from Firestore Auth Service
      userData = _authService.currentUserData;

      if (userData == null && _authService.currentUserId != null) {
        // If current data is null, try to fetch from Firestore
        userData = await _authService.getUserData(_authService.currentUserId!);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF052659),
          title: Text(
            'Logout',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar?',
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
                  await _authService.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                        (route) => false,
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
              child: Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showEditProfile() {
    final nameController = TextEditingController(text: userData?['fullName'] ?? '');
    final phoneController = TextEditingController(text: userData?['phoneNumber'] ?? '');
    final addressController = TextEditingController(text: userData?['address'] ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF052659),
          title: Text(
            'Edit Profile',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF7DA0CA)),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: phoneController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nomor Telepon',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF7DA0CA)),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: addressController,
                  style: TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Alamat',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF7DA0CA)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _authService.updateUserProfile(
                    fullName: nameController.text.trim(),
                    phoneNumber: phoneController.text.trim(),
                    address: addressController.text.trim(),
                  );

                  Navigator.pop(context);
                  _loadUserData(); // Refresh data

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Profile berhasil diupdate!'),
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
              child: Text('Simpan', style: TextStyle(color: Color(0xFF7DA0CA))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = screenWidth * 0.8;
    double cardHeight = cardWidth * 0.35;

    return Scaffold(
      backgroundColor: Color(0xFF021024),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7DA0CA)),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Kurangi jarak atas dari 50 menjadi 20
            SizedBox(height: 0),

            // Header dengan info user dan logout button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile',
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    // Edit button
                    IconButton(
                      onPressed: _showEditProfile,
                      icon: Icon(Icons.edit, color: Color(0xFF7DA0CA)),
                      tooltip: 'Edit Profile',
                    ),
                    // Logout button
                    IconButton(
                      onPressed: _logout,
                      icon: Icon(Icons.logout, color: Colors.red),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 20),

            // User Info Card (jika user login)
            if (userData != null) ...[
              Container(
                width: cardWidth,
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Color(0xFF052659),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Color(0xFF7DA0CA), width: 2),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF7DA0CA),
                      ),
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      userData!['fullName'] ?? 'User',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      userData!['email'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    if (userData!['phoneNumber'] != null && userData!['phoneNumber'].toString().isNotEmpty) ...[
                      SizedBox(height: 5),
                      Text(
                        userData!['phoneNumber'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(0xFF7DA0CA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'User ID: ${userData!['userId']}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Team Members Section
            Text(
              'Tim Pengembang',
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 15),

            // Team member cards
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return Container(
                    width: cardWidth,
                    height: cardHeight,
                    margin: EdgeInsets.only(bottom: 10),
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Color(0xff7DA0CA),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: cardHeight * 0.45,
                          height: cardHeight * 0.45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (member["image"] == null || member["image"]!.isEmpty)
                                ? Color(0xFF052659)
                                : Colors.transparent,
                          ),
                          child: (member["image"] == null || member["image"]!.isEmpty)
                              ? Icon(Icons.person, color: Colors.white, size: cardHeight * 0.3)
                              : ClipOval(
                            child: Image.asset(
                              member["image"]!,
                              fit: BoxFit.cover,
                              width: cardHeight * 0.45,
                              height: cardHeight * 0.45,
                            ),
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                member["name"]!,
                                style: TextStyle(
                                  fontSize: cardHeight * 0.18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 5),
                              Text(
                                member["id"]!,
                                style: TextStyle(
                                  fontSize: cardHeight * 0.15,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}