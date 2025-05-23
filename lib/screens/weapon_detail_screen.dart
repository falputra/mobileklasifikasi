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
          weapon['name'],
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
              height: 250,
              color: Color(0xFF333333),
              child: Image.asset(
                weapon['image'],
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
                    weapon['name'],
                    style: TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 10),

                  // Origin
                  _buildInfoRow(Icons.location_on, "Asal", "Jawa Barat"),

                  SizedBox(height: 20),

                  // Description title
                  Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 10),

                  // Description
                  Text(
                    _getWeaponDescription(weapon['name']),
                    style: TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: 20),

                  // Usage title
                  Text(
                    'Kegunaan',
                    style: TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 10),

                  // Usage
                  Text(
                    _getWeaponUsage(weapon['name']),
                    style: TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for info rows (icon + title + value)
  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF7DA0CA), size: 20),
          SizedBox(width: 8),
          Text(
            "$title: ",
            style: TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get description based on weapon name
  String _getWeaponDescription(String weaponName) {
    switch (weaponName.toLowerCase()) {
      case 'kujang':
        return 'Kujang adalah senjata tradisional dari Jawa Barat yang berbentuk melengkung dengan ujung yang runcing. Bentuknya yang khas melambangkan keseimbangan alam dan kehidupan. Kujang memiliki nilai filosofis tinggi bagi masyarakat Sunda dan sering digunakan sebagai simbol identitas budaya.';
      case 'bedog':
        return 'Bedog adalah sejenis golok atau parang dari Jawa Barat yang memiliki bentuk pipih dan lebar. Bedog memiliki bilah yang tebal dan kokoh, dengan panjang sekitar 30-40 cm. Senjata ini memiliki gagang yang terbuat dari kayu atau tanduk.';
      case 'golok':
        return 'Golok adalah senjata tradisional berbentuk parang dengan bilah yang lebar dan tebal. Golok khas Jawa Barat memiliki bentuk yang sedikit melengkung pada bagian ujungnya. Sarungnya biasanya terbuat dari kayu dan diukir dengan motif-motif tradisional.';
      case 'patik':
        return 'Patik adalah senjata tajam tradisional dari Jawa Barat yang bentuknya mirip pisau kecil dengan bilah yang lurus dan tajam pada satu sisi. Ukurannya lebih kecil dari golok atau bedog. Patik memiliki gagang yang biasanya terbuat dari kayu atau tanduk.';
      case 'congkrang':
        return 'Congkrang adalah senjata tradisional yang bentuknya mirip arit atau sabit dengan bilah melengkung dan tajam pada bagian dalamnya. Congkrang memiliki gagang yang biasanya terbuat dari kayu. ';
      case 'aniani':
        return 'ani-ani atau ketam adalah alat tradisional yang digunakan khusus untuk memanen padi. Meskipun lebih tepat dikategorikan sebagai perkakas pertanian daripada senjata, ani-ani memiliki bagian tajam yang berbentuk seperti pisau kecil yang terpasang pada pegangan kayu.';
      case 'sulimat':
        return 'Sulimat adalah senjata rahasia dari Jawa Barat yang bentuknya mirip dengan jarum atau pisau kecil yang sangat tajam. Ukurannya kecil sehingga mudah disembunyikan, biasanya di dalam pakaian atau aksesori. ';
      default:
        return 'Ini adalah senjata tradisional dari Jawa Barat. Senjata ini memiliki sejarah panjang dan nilai budaya yang tinggi bagi masyarakat Sunda.';
    }
  }

  // Helper method to get usage based on weapon name
  String _getWeaponUsage(String weaponName) {
    switch (weaponName.toLowerCase()) {
      case 'kujang':
        return 'Dahulu Kujang digunakan sebagai senjata perang dan alat pertanian. Namun sekarang lebih banyak digunakan sebagai hiasan atau benda pusaka. Kujang juga sering dijadikan simbol dalam lambang daerah di Jawa Barat.';
      case 'bedog':
        return 'Bedog terutama digunakan sebagai alat kerja untuk memotong, menebang, atau membelah benda keras seperti kayu. Selain itu, Bedog juga digunakan sebagai alat pertanian dan juga dapat berfungsi sebagai senjata untuk membela diri.';
     case 'golok':
        return 'Golok digunakan untuk berbagai keperluan seperti membuka jalan di hutan, memotong kayu, sebagai alat pertanian, dan juga sebagai senjata untuk membela diri. Di beberapa daerah, Golok juga digunakan dalam upacara adat tertentu.';
     case 'patik':
       return 'Senjata ini digunakan untuk keperluan sehari-hari seperti mengolah hasil pertanian, memotong tali, dan pekerjaan halus lainnya. Selain itu, patik juga bisa digunakan sebagai senjata untuk membela diri dalam jarak dekat.';
     case 'congkrang':
       return 'Senjata ini utamanya digunakan sebagai alat pertanian untuk memotong rumput, memanen padi, dan membersihkan semak belukar. Dalam situasi darurat, congkrang juga bisa digunakan sebagai senjata untuk membela diri.';
     case 'aniani':
      return 'Ani-ani digunakan dengan cara menggenggam batang padi dan memotongnya satu per satu, metode yang dianggap lebih menghormati Dewi Sri (dewi padi) dalam kepercayaan tradisional. Penggunaan ani-ani memungkinkan pemanenan yang selektif dan meminimalkan kerusakan tanaman.';
     case 'sulimat':
       return 'Sulimat digunakan sebagai senjata tikam jarak dekat dalam situasi membela diri atau pertarungan. Karena ukurannya yang kecil, sulimat sering digunakan sebagai senjata rahasia atau cadangan oleh para pendekar tradisional.';
       default:
        return 'Senjata ini memiliki berbagai kegunaan dalam kehidupan masyarakat tradisional, mulai dari alat pertanian, alat rumah tangga, hingga sebagai senjata untuk membela diri. Di masa sekarang, senjata ini lebih banyak dijadikan sebagai benda pusaka atau hiasan.';
    }
  }
}