// home_screen.dart - DESAIN SIMPEL TAPI BAGUS (MODIFIED)
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'weapon_detail_screen.dart';
import '../services/weapon_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isClassifying = false;
  final WeaponService _weaponService = WeaponService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF021024),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Header - Simple & Clean
              _buildHeader(),

              SizedBox(height: 40),

              // Main Card - Focus Area
              Expanded(
                child: _buildMainCard(),
              ),

              SizedBox(height: 20),

              // Database Status - Simple Info
              _buildDatabaseStatus(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Ikon swords tanpa border
        Container(
          width: 80,
          height: 80,
          child: Image.asset(
            'images/swords.png', // Ganti dengan path gambar swords Anda
            width: 80,
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback jika gambar tidak ditemukan
              return Icon(
                Icons.security,
                size: 40,
                color: Colors.white,
              );
            },
          ),
        ),

        SizedBox(height: 20),

        // Title - Clean Typography (MODIFIED)
        Text(
          'Klasifikasi Senjata\nTradisional Jawa Barat',
          style: TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 8),

        // Subtitle (MODIFIED)
        Text(
          'Ambil foto senjata tradisional untuk\nmengetahui jenis dan informasinya',
          style: TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 16,
            color: Colors.white60,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMainCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF052659).withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Color(0xFF7DA0CA).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image Area - Main Focus
          Expanded(
            flex: 3,
            child: _buildImageArea(),
          ),

          // Controls Area
          Padding(
            padding: EdgeInsets.all(24),
            child: _buildControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageArea() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedImage != null
              ? Color(0xFF7DA0CA).withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _selectedImage == null
            ? _buildEmptyImageState()
            : _buildSelectedImageState(),
      ),
    );
  }

  Widget _buildEmptyImageState() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with subtle animation effect
          TweenAnimationBuilder(
            duration: Duration(seconds: 2),
            tween: Tween<double>(begin: 0.8, end: 1.0),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Color(0xFF7DA0CA).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 36,
                    color: Color(0xFF7DA0CA),
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 16),

          Text(
            'Pilih Gambar Senjata',
            style: TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),

          SizedBox(height: 8),

          Text(
            'Ambil foto atau pilih dari galeri',
            style: TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImageState() {
    return Stack(
      children: [
        // Image
        Image.file(
          _selectedImage!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),

        // Overlay with remove button
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedImage = null;
              });
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        // Image Picker Buttons
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.camera_alt_outlined,
                label: 'Kamera',
                onPressed: _pickImageFromCamera,
                isPrimary: false,
              ),
            ),

            SizedBox(width: 12),

            Expanded(
              child: _buildActionButton(
                icon: Icons.photo_library_outlined,
                label: 'Galeri',
                onPressed: _pickImageFromGallery,
                isPrimary: false,
              ),
            ),
          ],
        ),

        SizedBox(height: 16),

        // Main Classify Button
        _buildActionButton(
          icon: _isClassifying ? Icons.hourglass_empty : Icons.search_rounded,
          label: _isClassifying ? 'Menganalisis...' : 'Klasifikasi Senjata',
          onPressed: _selectedImage == null ? null : _classifyWeaponFromDatabase,
          isPrimary: true,
          isFullWidth: true,
          isLoading: _isClassifying,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool isPrimary,
    bool isFullWidth = false,
    bool isLoading = false,
  }) {
    final isEnabled = onPressed != null;

    return Container(
      width: isFullWidth ? double.infinity : null,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Icon(icon, size: 20),
        label: Text(
          label,
          style: TextStyle(
            fontFamily: 'OpenSans',
            fontSize: isPrimary ? 16 : 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? (isEnabled ? Color(0xFF7DA0CA) : Colors.grey.withOpacity(0.3))
              : Colors.transparent,
          foregroundColor: Colors.white,
          side: isPrimary
              ? null
              : BorderSide(
            color: Color(0xFF7DA0CA).withOpacity(0.4),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isPrimary && isEnabled ? 8 : 0,
          shadowColor: isPrimary ? Color(0xFF7DA0CA).withOpacity(0.4) : null,
        ),
      ),
    );
  }

  Widget _buildDatabaseStatus() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFF052659).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFF7DA0CA).withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_outlined,
            size: 16,
            color: Color(0xFF7DA0CA),
          ),
          SizedBox(width: 8),
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('weapons').get(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final count = snapshot.data!.docs.length;
                return Text(
                  '$count senjata tersedia',
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    fontSize: 12,
                    color: Color(0xFF7DA0CA),
                    fontWeight: FontWeight.w500,
                  ),
                );
              }
              return Text(
                'Memuat data...',
                style: TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.4),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Image Picker Methods (unchanged)
  Future<void> _pickImageFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error mengambil gambar dari kamera');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error mengambil gambar dari galeri');
    }
  }

  Future<String> _convertImageToBase64(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) throw Exception('Invalid image file');

      final resizedImage = img.copyResize(
        originalImage,
        width: originalImage.width > 300 ? 300 : originalImage.width,
        height: originalImage.height > 300 ? 300 : originalImage.height,
      );

      final jpegBytes = img.encodeJpg(resizedImage, quality: 70);
      return base64Encode(jpegBytes);
    } catch (e) {
      throw Exception('Error processing image: $e');
    }
  }

  Future<void> _classifyWeaponFromDatabase() async {
    if (_selectedImage == null) return;

    setState(() {
      _isClassifying = true;
    });

    try {
      // Get weapons from Firestore
      final QuerySnapshot weaponsSnapshot = await FirebaseFirestore.instance
          .collection('weapons')
          .get();

      if (weaponsSnapshot.docs.isEmpty) {
        throw Exception('Tidak ada senjata dalam database! Tambahkan senjata terlebih dahulu.');
      }

      // Convert user image
      final userImageBase64 = await _convertImageToBase64(_selectedImage!);

      // Select random weapon
      final randomIndex = Random().nextInt(weaponsSnapshot.docs.length);
      final selectedDoc = weaponsSnapshot.docs[randomIndex];

      final selectedWeapon = Map<String, dynamic>.from(selectedDoc.data() as Map<String, dynamic>);
      selectedWeapon['id'] = selectedDoc.id;

      // Add user's image
      List<String> currentImages = [];
      if (selectedWeapon['images'] != null && selectedWeapon['images'] is List) {
        currentImages = List<String>.from(selectedWeapon['images']);
      } else if (selectedWeapon['image'] != null && selectedWeapon['image'].isNotEmpty) {
        currentImages = [selectedWeapon['image']];
      }

      currentImages.insert(0, userImageBase64);
      selectedWeapon['images'] = currentImages;
      selectedWeapon['image'] = userImageBase64;
      selectedWeapon['imageType'] = 'base64';

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Hasil: ${selectedWeapon['name']}'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate to detail
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WeaponDetailScreen(weapon: selectedWeapon),
        ),
      );

    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isClassifying = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}