import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/weapon_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img; // Import library image

class AddWeaponScreen extends StatefulWidget {
  @override
  _AddWeaponScreenState createState() => _AddWeaponScreenState();
}

class _AddWeaponScreenState extends State<AddWeaponScreen> {
  final _formKey = GlobalKey<FormState>();
  final WeaponService _weaponService = WeaponService();
  final _nameController = TextEditingController();
  final _imageController = TextEditingController();
  final _originController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _usageController = TextEditingController();
  bool _isLoading = false;
  File? _imageFile;

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
    final resizedImage = img.copyResize(originalImage!, width: 800); // Ubah ukuran sesuai kebutuhan
    final resizedFile = File(imageFile.path)..writeAsBytesSync(img.encodeJpg(resizedImage));
    return resizedFile;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imageController.text = pickedFile.path; // Set the path to the controller
      });
    }
  }

  Future<void> _addWeapon() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Resize image if necessary
        if (_imageFile != null) {
          _imageFile = await _resizeImage(_imageFile!);
        }

        // Upload image to Firebase Storage
        String imageUrl = await _uploadImageToFirebase(_imageFile!);

        final weaponData = {
          'name': _nameController.text.trim(),
          'image': imageUrl, // Use the URL from Firebase Storage
          'origin': _originController.text.trim(),
          'description': _descriptionController.text.trim(),
          'usage': _usageController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        };

        await _weaponService.addWeapon(weaponData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Senjata berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _nameController.clear();
        _imageController.clear();
        _originController.clear();
        _descriptionController.clear();
        _usageController.clear();
        _imageFile = null; // Reset image file

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
      // Create a reference to the Firebase Storage
      final storageRef = FirebaseStorage.instance.ref();
      // Create a unique file name
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      // Create a reference to the file location
      final imageRef = storageRef.child('weapons/$fileName.jpg');

      // Upload the file
      await imageRef.putFile(imageFile);

      // Get the download URL
      String downloadUrl = await imageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF021024), // Dark background theme
      appBar: AppBar(
        backgroundColor: Color(0xFF052659), // Dark blue AppBar
        title: Text(
          'Tambah Senjata',
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
                    labelText: 'Path Gambar',
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Path gambar tidak boleh kosong';
                    }
                    return null;
                  },
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
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                    'Tambah Senjata',
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