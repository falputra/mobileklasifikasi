import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/custom_button.dart';
import 'dart:io';
import 'dart:math'; // Import untuk Random
import 'weapon_detail_screen.dart'; // Import WeaponDetailScreen

class HomeScreen extends StatelessWidget {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(BuildContext context) async {
    final pickedFile = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Ambil dari Kamera'),
                onTap: () async {
                  final picked = await _picker.pickImage(source: ImageSource.camera);
                  Navigator.pop(context, picked);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Pilih dari Galeri'),
                onTap: () async {
                  final picked = await _picker.pickImage(source: ImageSource.gallery);
                  Navigator.pop(context, picked);
                },
              ),
            ],
          ),
        );
      },
    );

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      // Di sini tambahkan kode untuk mengklasifikasikan senjata
      // Ini hanya contoh sederhana, dalam implementasi nyata Anda perlu menggunakan model ML
      final detectedWeapon = await _classifyWeapon(imageFile);

      // Arahkan ke WeaponDetailScreen dengan data senjata yang terdeteksi
      if (detectedWeapon != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WeaponDetailScreen(weapon: detectedWeapon),
          ),
        );
      } else {
        // Tampilkan pesan jika tidak berhasil mendeteksi senjata
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tidak dapat mendeteksi senjata dari gambar ini'))
        );
      }
    }
  }

  // Method untuk mengklasifikasikan senjata dari gambar
  Future<Map<String, dynamic>?> _classifyWeapon(File imageFile) async {
    // Daftar senjata yang bisa dideteksi
    final List<Map<String, dynamic>> weapons = [
      {'name': 'Kujang', 'image': 'images/kujang.png'},
      {'name': 'Bedog', 'image': 'images/bedog.png'},
      {'name': 'Golok', 'image': 'images/golok.jpg'},
      {'name': 'Patik', 'image': 'images/patik.webp'},
      {'name': 'Congkrang', 'image': 'images/congkrang.webp'},
      {'name': 'Ani-ani (Ketam)', 'image': 'images/aniani.webp'},
      {'name': 'Sulimat', 'image': 'images/sulimat.jpg'},
    ];

    // Print untuk debugging
    print('Memilih senjata acak dari ${weapons.length} pilihan');

    // Memastikan random benar-benar acak dengan menggunakan DateTime sebagai seed
    final random = Random(DateTime.now().millisecondsSinceEpoch);
    final randomIndex = random.nextInt(weapons.length);

    print('Indeks terpilih: $randomIndex, Senjata: ${weapons[randomIndex]['name']}');

    return weapons[randomIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 90),
          Text(
            'Welcome to\nKlasifikasi Senjata \nTradisional Jawa Barat',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 40),
          Text(
            'Masukkan gambar senjata tradisional\nJawa Barat untuk diklasifikasi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 20),
          CustomButton(
            icon: Icons.image,
            text: 'Pilih Gambar',
            onPressed: () => _pickImage(context),
          ),
        ],
      ),
    );
  }
}