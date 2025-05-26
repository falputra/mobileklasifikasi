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
      appBar: AppBar(
        title: Text('Tambah Senjata'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nama Senjata'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama senjata tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Image field
              TextFormField(
                controller: _imageController,
                decoration: InputDecoration(
                  labelText: 'Path Gambar',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.photo),
                    onPressed: _pickImage,
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Path gambar tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Origin field
              TextFormField(
                controller: _originController,
                decoration: InputDecoration(labelText: 'Asal Daerah'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Asal daerah tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Deskripsi'),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Deskripsi tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Usage field
              TextFormField(
                controller: _usageController,
                decoration: InputDecoration(labelText: 'Kegunaan'),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kegunaan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 40),

              // Submit button
              ElevatedButton(
                onPressed: _isLoading ? null : _addWeapon,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Tambah Senjata'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}