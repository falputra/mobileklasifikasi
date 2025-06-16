import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:cloud_firestore/cloud_firestore.dart';  // ADD THIS
import '../services/weapon_service.dart';
import 'edit_weapon_screen.dart';

class WeaponDetailScreen extends StatefulWidget {
  final Map<String, dynamic> weapon;

  WeaponDetailScreen({required this.weapon});

  @override
  _WeaponDetailScreenState createState() => _WeaponDetailScreenState();
}

class _WeaponDetailScreenState extends State<WeaponDetailScreen> {
  final WeaponService _weaponService = WeaponService();
  PageController _pageController = PageController();
  int _currentImageIndex = 0;
  List<String> _images = [];
  bool _isAddingImage = false;

  @override
  void initState() {
    super.initState();
    _initializeImages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initializeImages() {
    // Handle different image storage formats
    if (widget.weapon['images'] != null && widget.weapon['images'] is List) {
      // New format: multiple images
      _images = List<String>.from(widget.weapon['images']);
    } else if (widget.weapon['image'] != null && widget.weapon['image'].isNotEmpty) {
      // Old format: single image
      _images = [widget.weapon['image']];
    } else {
      // No images
      _images = [];
    }
    print('📸 Initialized ${_images.length} images for ${widget.weapon['name']}');
  }

  // Helper method to build weapon image with Base64 support
  Widget _buildWeaponImage(String? imageData, String? imageType, {bool isZoomable = true}) {
    // If no image data or empty, show placeholder
    if (imageData == null || imageData.isEmpty) {
      return Container(
        color: Color(0xFF052659),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: Colors.white54,
                size: 80,
              ),
              SizedBox(height: 10),
              Text(
                'Tidak ada gambar',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget imageWidget;

    // Check if it's Base64 image
    if (imageType == 'base64' || (!imageData.startsWith('http') && !imageData.startsWith('images/'))) {
      try {
        final bytes = base64Decode(imageData);
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.contain,
          width: double.infinity,
          height: 300,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading Base64 image: $error');
            return _buildErrorPlaceholder('Gambar rusak');
          },
        );
      } catch (e) {
        print('Error decoding Base64 image: $e');
        return _buildErrorPlaceholder('Error memuat gambar');
      }
    }
    // Check if it's a network URL (from Firebase Storage)
    else if (imageData.startsWith('http')) {
      imageWidget = Image.network(
        imageData,
        fit: BoxFit.contain,
        width: double.infinity,
        height: 300,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 300,
            color: Color(0xFF052659),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7DA0CA)),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Memuat gambar...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading network image: $error');
          return _buildErrorPlaceholder('Gagal memuat gambar');
        },
      );
    } else {
      // Fallback to asset image (for old data or local images)
      imageWidget = Image.asset(
        imageData,
        fit: BoxFit.contain,
        width: double.infinity,
        height: 300,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading asset image: $error');
          return _buildErrorPlaceholder('Gambar tidak ditemukan');
        },
      );
    }

    // Add zoom functionality if requested
    if (isZoomable) {
      return InteractiveViewer(
        panEnabled: true,
        boundaryMargin: EdgeInsets.all(20),
        minScale: 0.5,
        maxScale: 3.0,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildErrorPlaceholder(String message) {
    return Container(
      height: 300,
      color: Color(0xFF052659),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              color: Colors.white54,
              size: 80,
            ),
            SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _convertImageToBase64(File imageFile) async {
    try {
      print('🔄 Converting additional image to Base64...');

      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();

      // Decode image
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) throw Exception('Invalid image file');

      // Resize untuk menghemat space - max 400px for detail images
      final resizedImage = img.copyResize(
        originalImage,
        width: originalImage.width > 400 ? 400 : originalImage.width,
        height: originalImage.height > 400 ? 400 : originalImage.height,
      );

      // Convert to JPEG dengan quality 70%
      final jpegBytes = img.encodeJpg(resizedImage, quality: 70);

      // Convert to Base64
      final base64String = base64Encode(jpegBytes);

      print('✅ Additional image converted to Base64');
      print('📏 Base64 size: ${base64String.length} characters');

      // Check if Base64 is too large
      if (base64String.length > 600000) { // ~600KB limit
        throw Exception('Gambar terlalu besar. Pilih gambar yang lebih kecil.');
      }

      return base64String;
    } catch (e) {
      print('❌ Error converting additional image to Base64: $e');
      throw Exception('Error processing image: $e');
    }
  }

  Future<void> _addNewImage() async {
    if (_isAddingImage) return;

    try {
      setState(() {
        _isAddingImage = true;
      });

      print('🔄 Adding new image to weapon...');

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        print('✅ New image picked: ${pickedFile.path}');

        final imageFile = File(pickedFile.path);

        // Convert to Base64
        final base64String = await _convertImageToBase64(imageFile);

        // Add to images list
        final updatedImages = List<String>.from(_images);
        updatedImages.add(base64String);

        // Update weapon in database
        final weaponData = {
          'images': updatedImages,
          'imageType': 'base64',
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Also update the main 'image' field for backward compatibility
        if (updatedImages.isNotEmpty) {
          weaponData['image'] = updatedImages.first;
        }

        await _weaponService.updateWeapon(widget.weapon['id'], weaponData);

        // Update local state
        setState(() {
          _images = updatedImages;
          _currentImageIndex = _images.length - 1; // Navigate to new image
        });

        // Navigate to the new image
        if (_images.length > 1) {
          _pageController.animateToPage(
            _currentImageIndex,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gambar berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );

        print('✅ New image added successfully');
      }
    } catch (e) {
      print('❌ Error adding new image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isAddingImage = false;
      });
    }
  }

  Future<void> _deleteImage(int index) async {
    if (_images.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak bisa menghapus gambar terakhir!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF052659),
          title: Text(
            'Hapus Gambar',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus gambar ini?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // Remove from images list
        final updatedImages = List<String>.from(_images);
        updatedImages.removeAt(index);

        // Update weapon in database
        final weaponData = {
          'images': updatedImages,
          'imageType': 'base64',
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Update main 'image' field for backward compatibility
        if (updatedImages.isNotEmpty) {
          weaponData['image'] = updatedImages.first;
        }

        await _weaponService.updateWeapon(widget.weapon['id'], weaponData);

        // Update local state
        setState(() {
          _images = updatedImages;
          if (_currentImageIndex >= _images.length) {
            _currentImageIndex = _images.length - 1;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gambar berhasil dihapus!'),
            backgroundColor: Colors.green,
          ),
        );

        print('✅ Image deleted successfully');
      } catch (e) {
        print('❌ Error deleting image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF021024),
      appBar: AppBar(
        backgroundColor: Color(0xFF052659),
        title: Text(
          widget.weapon['name'] ?? 'Detail Senjata',
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
        actions: [
          // Add image button
          IconButton(
            icon: _isAddingImage
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Icon(Icons.add_photo_alternate),
            onPressed: _isAddingImage ? null : _addNewImage,
            tooltip: 'Tambah Gambar',
          ),
          // Delete current image button
          if (_images.length > 1)
            IconButton(
              icon: Icon(Icons.delete_outline),
              onPressed: () => _deleteImage(_currentImageIndex),
              tooltip: 'Hapus Gambar Ini',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Gallery Section
            Container(
              width: double.infinity,
              height: 300,
              color: Color(0xFF052659),
              child: _images.isEmpty
                  ? _buildWeaponImage(null, null, isZoomable: false)
                  : Stack(
                children: [
                  // Image PageView
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _buildWeaponImage(
                        _images[index],
                        widget.weapon['imageType'] ?? 'base64',
                        isZoomable: true,
                      );
                    },
                  ),

                  // Image counter overlay (top right)
                  if (_images.length > 1)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1} / ${_images.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Navigation arrows
                  if (_images.length > 1) ...[
                    // Left arrow
                    if (_currentImageIndex > 0)
                      Positioned(
                        left: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.chevron_left, color: Colors.white),
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                    // Right arrow
                    if (_currentImageIndex < _images.length - 1)
                      Positioned(
                        right: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.chevron_right, color: Colors.white),
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),

            // Image indicators (dots)
            if (_images.length > 1)
              Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _images.length,
                        (index) => Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      width: _currentImageIndex == index ? 12 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentImageIndex == index
                            ? Color(0xFF7DA0CA)
                            : Colors.white30,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
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
                    widget.weapon['name'] ?? 'Unknown Weapon',
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
                          widget.weapon['origin'] ?? 'Unknown Origin',
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
                    content: widget.weapon['description'] ?? 'Tidak ada deskripsi',
                    icon: Icons.description,
                  ),

                  SizedBox(height: 25),

                  // Usage section
                  _buildInfoSection(
                    title: 'Kegunaan',
                    content: widget.weapon['usage'] ?? 'Tidak ada informasi kegunaan',
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditWeaponScreen(weapon: widget.weapon),
                              ),
                            );
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
                'Bagikan informasi tentang ${widget.weapon['name']}:',
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
                  '${widget.weapon['name']} - Senjata tradisional dari ${widget.weapon['origin']}\n\n${widget.weapon['description'] ?? 'Senjata tradisional Indonesia'}\n\nMemiliki ${_images.length} foto.',
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