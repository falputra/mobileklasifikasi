import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/weapon_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as img;

class AddWeaponScreen extends StatefulWidget {
  @override
  _AddWeaponScreenState createState() => _AddWeaponScreenState();
}

class _AddWeaponScreenState extends State<AddWeaponScreen> {
  final _formKey = GlobalKey<FormState>();
  final WeaponService _weaponService = WeaponService();
  final _nameController = TextEditingController();
  final _originController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _usageController = TextEditingController();
  bool _isLoading = false;

  // Multiple images support
  List<File> _imageFiles = [];
  List<String> _imageBase64List = [];
  PageController _previewController = PageController();
  int _currentPreviewIndex = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _originController.dispose();
    _descriptionController.dispose();
    _usageController.dispose();
    _previewController.dispose();
    super.dispose();
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

  Future<void> _pickImages() async {
    try {
      print('🔄 Starting multiple image picker...');

      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        print('✅ ${pickedFiles.length} images picked');

        // Convert picked files to File objects
        final newImageFiles = pickedFiles.map((xFile) => File(xFile.path)).toList();

        setState(() {
          _imageFiles.addAll(newImageFiles);
        });

        // Convert all new images to Base64
        for (final imageFile in newImageFiles) {
          try {
            final base64String = await _convertImageToBase64(imageFile);
            setState(() {
              _imageBase64List.add(base64String);
            });
          } catch (e) {
            print('❌ Error processing image: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error memproses salah satu gambar: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_imageFiles.length} gambar berhasil dipilih!'),
            backgroundColor: Colors.green,
          ),
        );

        print('✅ All images processed successfully');
      } else {
        print('⚠️ No images selected');
      }
    } catch (e) {
      print('❌ Error picking images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error memilih gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickSingleImage() async {
    try {
      print('🔄 Starting single image picker...');

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        print('✅ Single image picked');

        final imageFile = File(pickedFile.path);

        setState(() {
          _imageFiles.add(imageFile);
        });

        // Convert to Base64
        try {
          final base64String = await _convertImageToBase64(imageFile);
          setState(() {
            _imageBase64List.add(base64String);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gambar berhasil ditambahkan!'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          print('❌ Error processing single image: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error memproses gambar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error picking single image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error memilih gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
      _imageBase64List.removeAt(index);
      if (_currentPreviewIndex >= _imageFiles.length && _imageFiles.isNotEmpty) {
        _currentPreviewIndex = _imageFiles.length - 1;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gambar dihapus'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _addWeapon() async {
    if (_formKey.currentState!.validate()) {
      // Validasi gambar
      if (_imageFiles.isEmpty || _imageBase64List.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pilih minimal 1 gambar!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        print('🔄 Starting weapon creation with ${_imageBase64List.length} images...');

        // Create weapon data dengan multiple images
        final weaponData = {
          'name': _nameController.text.trim(),
          'images': _imageBase64List,  // Array of Base64 strings
          'image': _imageBase64List.first,  // Backward compatibility
          'imageType': 'base64',
          'origin': _originController.text.trim(),
          'description': _descriptionController.text.trim(),
          'usage': _usageController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        };

        print('🔄 Saving weapon data to Firestore...');
        await _weaponService.addWeapon(weaponData);

        print('✅ Weapon added successfully with ${_imageBase64List.length} images!');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Senjata berhasil ditambahkan dengan ${_imageFiles.length} gambar!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _nameController.clear();
        _originController.clear();
        _descriptionController.clear();
        _usageController.clear();
        setState(() {
          _imageFiles.clear();
          _imageBase64List.clear();
          _currentPreviewIndex = 0;
        });

        // Return to previous screen
        Navigator.pop(context);

      } catch (e) {
        print('❌ Error adding weapon: $e');
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
          'Tambah Senjata (Multi-Photo)',
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
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.photo_library, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mode MULTI-PHOTO - Multiple Images',
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Tambahkan beberapa foto untuk satu senjata',
                            style: TextStyle(color: Colors.blue, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

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
                    // Image picker buttons
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.photo_library, color: Color(0xFF7DA0CA)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _imageFiles.isEmpty
                                  ? 'Pilih Gambar Senjata'
                                  : '${_imageFiles.length} gambar dipilih',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          ),
                          // Multiple images button
                          Container(
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.photo_library, color: Colors.white),
                              onPressed: _isLoading ? null : _pickImages,
                              tooltip: 'Pilih Multiple Gambar',
                            ),
                          ),
                          // Single image button
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFF7DA0CA),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.photo, color: Colors.white),
                              onPressed: _isLoading ? null : _pickSingleImage,
                              tooltip: 'Pilih 1 Gambar',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Image preview gallery
                    if (_imageFiles.isNotEmpty) ...[
                      Divider(color: Colors.white30, height: 1),
                      Container(
                        height: 200,
                        child: Stack(
                          children: [
                            // Image PageView
                            PageView.builder(
                              controller: _previewController,
                              itemCount: _imageFiles.length,
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
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _imageFiles[index],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  ),
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

                            // Image counter
                            if (_imageFiles.length > 1)
                              Positioned(
                                top: 16,
                                left: 16,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_currentPreviewIndex + 1} / ${_imageFiles.length}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Image indicators
                      if (_imageFiles.length > 1)
                        Container(
                          padding: EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _imageFiles.length,
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

              // Submit button
              Container(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addWeapon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7DA0CA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                    'Tambah Senjata (${_imageFiles.length} foto)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}