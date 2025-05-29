import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/weapon_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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
  final _imageController = TextEditingController();
  final _originController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _usageController = TextEditingController();
  bool _isLoading = false;
  File? _imageFile;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    // Initialize form dengan data weapon yang ada
    _nameController.text = widget.weapon['name'] ?? '';
    _originController.text = widget.weapon['origin'] ?? '';
    _descriptionController.text = widget.weapon['description'] ?? '';
    _usageController.text = widget.weapon['usage'] ?? '';
    _currentImageUrl = widget.weapon['image'];
    _imageController.text = _currentImageUrl ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageController.dispose();
    _originController.dispose();
    _descriptionController.dispose();
    _usageController.dispose();
    super.dispose();
  }

  Future<File> _resizeImage(File imageFile) async {
    final originalImage = img.decodeImage(await imageFile.readAsBytes());
    final resizedImage = img.copyResize(originalImage!, width: 800);
    final resizedFile = File(imageFile.path)..writeAsBytesSync(img.encodeJpg(resizedImage));
    return resizedFile;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imageController.text = 'Gambar baru dipilih: ${pickedFile.name}';
      });
    }
  }

  Future<void> _updateWeapon() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String imageUrl = _currentImageUrl ?? '';

        // Jika ada gambar baru yang dipilih, upload ke Firebase Storage
        if (_imageFile != null) {
          // Hapus gambar lama jika ada
          if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
            try {
              await FirebaseStorage.instance.refFromURL(_currentImageUrl!).delete();
            } catch (e) {
              print('Error deleting old image: $e');
              // Lanjutkan meskipun gagal hapus gambar lama
            }
          }

          // Resize dan upload gambar baru
          _imageFile = await _resizeImage(_imageFile!);
          imageUrl = await _uploadImageToFirebase(_imageFile!);
        }

        final weaponData = {
          'name': _nameController.text.trim(),
          'image': imageUrl,
          'origin': _originController.text.trim(),
          'description': _descriptionController.text.trim(),
          'usage': _usageController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await _weaponService.updateWeapon(widget.weapon['id'], weaponData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Senjata berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );

        // Kembali ke halaman sebelumnya
        Navigator.pop(context);

      } catch (e) {
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

  Future<String> _uploadImageToFirebase(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final imageRef = storageRef.child('weapons/$fileName.jpg');

      await imageRef.putFile(imageFile);
      String downloadUrl = await imageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF021024),
      appBar: AppBar(
        backgroundColor: Color(0xFF052659),
        title: Text(
          'Edit Senjata',
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
              SizedBox(height: 10),

              // Current weapon info card
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Color(0xFF052659),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF7DA0CA)),
                ),
                child: Row(
                  children: [
                    // Current image preview
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Color(0xFF0a3067),
                      ),
                      child: _currentImageUrl != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _currentImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.image_not_supported, color: Colors.white54);
                          },
                        ),
                      )
                          : Icon(Icons.image_not_supported, color: Colors.white54),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mengedit: ${widget.weapon['name']}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Asal: ${widget.weapon['origin']}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
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

              // Image field
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF052659),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  controller: _imageController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Gambar Senjata',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.image, color: Color(0xFF7DA0CA)),
                    suffixIcon: Container(
                      margin: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF7DA0CA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.photo, color: Colors.white),
                        onPressed: _pickImage,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  readOnly: true,
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
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                        'Perbarui Senjata',
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