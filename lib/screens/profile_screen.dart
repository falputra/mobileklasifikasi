import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final List<Map<String, String>> members = [
    {"name": "Ali Abdurrahman Hakim", "id": "2307413015"},
    {"name": "Muhammad Hilmi Bilad", "id": "2307413022", "image": "images/WUKONGPC.png"},
    {"name": "Naufal Putra Hasan", "id": "2307413009"},
  ];

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = screenWidth * 0.8;
    double cardHeight = cardWidth * 0.35;

    return Scaffold(
      backgroundColor: Color(0xFF021024),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 50),
            Text(
              'Profile',
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            Column(
              children: members.map((member) {
                return Align(
                  alignment: Alignment.center, // Membuat card sejajar tengah
                  child: Container(
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
                                ? Color(0xFF052659) // Warna biru hanya jika tidak ada gambar
                                : Colors.transparent, // Hapus warna latar belakang jika ada gambar
                          ),
                          child: (member["image"] == null || member["image"]!.isEmpty)
                              ? Icon(Icons.person, color: Colors.white, size: cardHeight * 0.3)
                              : ClipOval( // Memastikan gambar tetap bulat
                                  child: Image.asset(
                                    member["image"]!,
                                    fit: BoxFit.cover, // Pastikan gambar menutupi lingkaran sepenuhnya
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
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
