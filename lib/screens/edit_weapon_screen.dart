import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/weapon_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as img;

class EditWeaponScreen extends StatefulWidget {
  final Map<String, dynamic> weapon;

  EditWeaponScreen({required this.weapon});

  @override
  _EditWeaponScreenState createState() => _EditWeaponScreenState();
}

class _EditWeaponScreenState extends State<EditWeaponScreen> {
  final _formKey = GlobalKey<FormState>();
  final WeaponService _weaponService = WeaponService();
  final _nameController = TextEditingController();
  final _originController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _usageController = TextEditingController();
  bool _isLoading = false;
  bool _isAddingImages = false;

  // Multiple images support
  List<String> _currentImages = [];
  List<File> _newImageFiles = [];
  PageController _previewController = PageController();
  int _currentPreviewIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Initialize form dengan data weapon yang ada
    _nameController.text = widget.weapon['name'] ?? '';
    _originController.text = widget.weapon['origin'] ?? '';
    _descriptionController.text = widget.weapon['description'] ?? '';
    _usageController.text = widget.weapon['usage'] ?? '';

    // Initialize images
    if (widget.weapon['images'] != null && widget.weapon['images'] is List) {
      _currentImages = List<String>.from(widget.weapon['images']);
    } else if (widget.weapon['image'] != null && widget.weapon['image'].isNotEmpty) {
      _currentImages = [widget.weapon['image']];
    }

    print('🔄 Edit initialized with ${_currentImages.length} existing images');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _originController.dispose();
    _descriptionController.dispose();
    _usageController.dispose();
    _previewController.dispose();
    super.dispose();
  }

  int get getTotalImages => _currentImages.length + _newImageFiles.length;

  // Helper method to build image (current or new)
  Widget _buildImagePreview(int index) {
    final totalCurrentImages = _currentImages.length;

    if (index < totalCurrentImages) {
      // Display current image
      final imageData = _currentImages[index];

      if (imageData.startsWith('http')) {
        // Network image
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageData,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: Icon(Icons.broken_image, size: 50, color: Colors.grey[600]),
              );
            },
          ),
        );
      } else {
        // Base64 image
        try {
          final bytes = base64Decode(imageData);
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey[600]),
                );
              },
            ),
          );
        } catch (e) {
          return Container(
            color: Colors.grey[300],
            child: Icon(Icons.broken_image, size: 50, color: Colors.grey[600]),
          );
        }
      }
    } else {
      // Display new image
      final newIndex = index - totalCurrentImages;
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          _newImageFiles[newIndex],
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }
  }

  Future<String> _convertImageToBase64(File imageFile) async {
    try {
      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();

      // Decode image
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) throw Exception('Invalid image file');

      // Resize untuk menghemat space - max 400px
      final resizedImage = img.copyResize(
        originalImage,
        width: originalImage.width > 400 ? 400 : originalImage.width,
        height: originalImage.height > 400 ? 400 : originalImage.height,
      );

      // Convert to JPEG dengan quality 70%
      final jpegBytes = img.encodeJpg(resizedImage, quality: 70);

      // Convert to Base64
      final base64String = base64Encode(jpegBytes);

      // Check if Base64 is too large
      if (base64String.length > 600000) { // ~600KB limit
        throw Exception('Gambar terlalu besar. Pilih gambar yang lebih kecil.');
      }

      return base64String;
    } catch (e) {
      throw Exception('Error processing image: $e');
    }
  }

  Future<void> _addNewImages() async {
    if (_isAddingImages) return;

    setState(() {
      _isAddingImages = true;
    });

    try {
      print('🔄 Adding new images to edit...');

      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        print('✅ ${pickedFiles.length} new images picked for edit');

        final newFiles = pickedFiles.map((xFile) => File(xFile.path)).toList();

        setState(() {
          _newImageFiles.addAll(newFiles);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pickedFiles.length} gambar baru ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error adding new images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error menambah gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isAddingImages = false;
      });
    }
  }

  Future<void> _addSingleImage() async {
    if (_isAddingImages) return;

    setState(() {
      _isAddingImages = true;
    });

    try {
      print('🔄 Adding single image to edit...');

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        print('✅ Single image picked for edit');

        final newFile = File(pickedFile.path);

        setState(() {
          _newImageFiles.add(newFile);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gambar berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error adding single image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error menambah gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isAddingImages = false;
      });
    }
  }

  void _removeImage(int index) {
    final totalCurrentImages = _currentImages.length;

    if (index < totalCurrentImages) {
      // Remove from current images
      if (_currentImages.length <= 1 && _newImageFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak bisa menghapus semua gambar!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _currentImages.removeAt(index);
        if (_currentPreviewIndex >= getTotalImages && getTotalImages > 0) {
          _currentPreviewIndex = getTotalImages - 1;
        }
      });
    } else {
      // Remove from new images
      final newIndex = index - totalCurrentImages;
      setState(() {
        _newImageFiles.removeAt(newIndex);
        if (_currentPreviewIndex >= getTotalImages && getTotalImages > 0) {
          _currentPreviewIndex = getTotalImages - 1;
        }
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gambar dihapus'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _updateWeapon() async {
    if (_formKey.currentState!.validate()) {
      // Validasi gambar - minimal 1 gambar
      if (getTotalImages == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Minimal harus ada 1 gambar!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        print('🔄 Starting weapon update with ${getTotalImages} total images...');

        // Prepare final images list
        List<String> finalImages = List<String>.from(_currentImages);

        // Convert new images to Base64 and add to final list
        for (final newImageFile in _newImageFiles) {
          try {
            final base64String = await _convertImageToBase64(newImageFile);
            finalImages.add(base64String);
          } catch (e) {
            print('❌ Error converting new image: $e');
            // Continue with other images even if one fails
          }
        }

        // Prepare weapon data
        final weaponData = {
          'name': _nameController.text.trim(),
          'images': finalImages,  // Array of all images
          'image': finalImages.isNotEmpty ? finalImages.first : '',  // Backward compatibility
          'imageType': 'base64',
          'origin': _originController.text.trim(),
          'description': _descriptionController.text.trim(),
          'usage': _usageController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        print('🔄 Updating weapon in Firestore with ${finalImages.length} images...');
        await _weaponService.updateWeapon(widget.weapon['id'], weaponData);

        print('✅ Weapon updated successfully!');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Senjata berhasil diperbarui dengan ${finalImages.length} gambar!'),
            backgroundColor: Colors.green,
          ),
        );

        // Return to previous screen
        Navigator.pop(context, true); // Return true to indicate success

      } catch (e) {
        print('❌ Error updating weapon: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
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
          'Edit Senjata (Multi-Photo)',
          style: TextStyle(
            fontFamily: 'OpenSans',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.orange),  // Changed from Icons.edit_photo
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Mode - Multi-Photo Support',
                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Edit data dan kelola multiple foto senjata',
                            style: TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Current weapon info card
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Color(0xFF052659),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF7DA0CA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF7DA0CA)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Mengedit: ${widget.weapon['name']}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Asal: ${widget.weapon['origin']} • Total Foto: ${getTotalImages}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    if (_newImageFiles.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_newImageFiles.length} foto baru ditambahkan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // Name field
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF052659),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nama Senjata',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.label, color: Color(0xFF7DA0CA)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama senjata tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 20),

              // Images section
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF052659),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Image management header
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.photo_library, color: Color(0xFF7DA0CA)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Kelola Foto (${getTotalImages} foto)',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Action buttons row
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // Add multiple images button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isAddingImages ? null : _addNewImages,
                              icon: _isAddingImages
                                  ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                                  : Icon(Icons.photo_library, size: 18),
                              label: Text('Multiple', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          // Add single image button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isAddingImages ? null : _addSingleImage,
                              icon: Icon(Icons.add_photo_alternate, size: 18),
                              label: Text('Single', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF7DA0CA),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Image preview gallery
                    if (getTotalImages > 0) ...[
                      Divider(color: Colors.white30, height: 24),
                      Container(
                        height: 200,
                        child: Stack(
                          children: [
                            // Image PageView
                            PageView.builder(
                              controller: _previewController,
                              itemCount: getTotalImages,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentPreviewIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: _buildImagePreview(index),
                                );
                              },
                            ),

                            // Delete button overlay
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.white, size: 20),
                                  onPressed: () => _removeImage(_currentPreviewIndex),
                                  tooltip: 'Hapus Gambar Ini',
                                ),
                              ),
                            ),

                            // Image counter and type indicator
                            Positioned(
                              top: 16,
                              left: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_currentPreviewIndex + 1} / ${getTotalImages}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (_currentPreviewIndex >= _currentImages.length)
                                    Container(
                                      margin: EdgeInsets.only(top: 4),
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'BARU',
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
                        ),
                      ),

                      // Image indicators
                      if (getTotalImages > 1)
                        Container(
                          padding: EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              getTotalImages,
                                  (index) => Container(
                                margin: EdgeInsets.symmetric(horizontal: 2),
                                width: _currentPreviewIndex == index ? 8 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _currentPreviewIndex == index
                                      ? Color(0xFF7DA0CA)
                                      : Colors.white30,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: 8),
                    ] else ...[
                      // No images state
                      Container(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.photo_library_outlined, color: Colors.white54, size: 48),
                            SizedBox(height: 12),
                            Text(
                              'Belum ada foto',
                              style: TextStyle(color: Colors.white54, fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tambahkan foto menggunakan tombol di atas',
                              style: TextStyle(color: Colors.white38, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Origin field
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF052659),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  controller: _originController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Asal Daerah',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.place, color: Color(0xFF7DA0CA)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Asal daerah tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 20),

              // Description field
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF052659),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  controller: _descriptionController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Deskripsi',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.description, color: Color(0xFF7DA0CA)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Deskripsi tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 20),

              // Usage field
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF052659),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  controller: _usageController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Kegunaan',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.build, color: Color(0xFF7DA0CA)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kegunaan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 40),

              // Action buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white70),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'OpenSans',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 15),
                  // Update button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateWeapon,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF7DA0CA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: _isLoading
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Menyimpan...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                          : Text(
                        'Update (${getTotalImages} foto)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'OpenSans',
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
      ),
    );
  }
}