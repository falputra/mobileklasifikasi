// services/firestore_auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FirestoreAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';
  String? _currentUserId;
  Map<String, dynamic>? _currentUserData;

  // Get current user ID
  String? get currentUserId => _currentUserId;

  // Get current user data
  Map<String, dynamic>? get currentUserData => _currentUserData;

  // Check if user is logged in
  bool get isLoggedIn => _currentUserId != null;

  // Initialize auth service
  Future<void> initializeAuth() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('current_user_id');

      if (_currentUserId != null) {
        await _loadCurrentUserData();
        print('✅ User restored from session: $_currentUserId');
      } else {
        print('ℹ️ No saved session found');
      }
    } catch (e) {
      print('❌ Error initializing auth: $e');
    }
  }

  // Hash password dengan salt
  String _hashPassword(String password, String email) {
    final salt = email.toLowerCase(); // Menggunakan email sebagai salt
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate unique user ID
  String _generateUserId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
  }

  // Register new user
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Validasi input
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw Exception('Format email tidak valid');
      }

      if (password.length < 6) {
        throw Exception('Password minimal 6 karakter');
      }

      // Check if email already exists
      final existingUser = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email.toLowerCase())
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw Exception('Email sudah digunakan');
      }

      // Generate user ID
      final userId = _generateUserId();

      // Hash password
      final hashedPassword = _hashPassword(password, email);

      // Create user data
      final userData = {
        'userId': userId,
        'email': email.toLowerCase(),
        'fullName': fullName.trim(),
        'password': hashedPassword,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
        'profileImageUrl': '',
        'phoneNumber': '',
        'address': '',
        'role': 'user',
      };

      // Save to Firestore
      await _firestore.collection(_collection).doc(userId).set(userData);

      // Set current user
      _currentUserId = userId;
      _currentUserData = userData;

      // Save session
      await _saveSession(userId);

      print('✅ User registered successfully: $userId');
      return {
        'success': true,
        'userId': userId,
        'userData': userData,
      };

    } catch (e) {
      print('❌ Registration error: $e');
      throw Exception('Error creating account: $e');
    }
  }

  // Login user
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // Hash password dengan email sebagai salt
      final hashedPassword = _hashPassword(password, email);

      // Find user with email and password
      final userQuery = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email.toLowerCase())
          .where('password', isEqualTo: hashedPassword)
          .where('isActive', isEqualTo: true)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('Email atau password salah');
      }

      final userDoc = userQuery.docs.first;
      final userData = userDoc.data();

      // Update last login
      await _firestore.collection(_collection).doc(userDoc.id).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // Set current user
      _currentUserId = userDoc.id;
      _currentUserData = userData;

      // Save session
      await _saveSession(userDoc.id);

      print('✅ Login successful: ${userDoc.id}');
      return {
        'success': true,
        'userId': userDoc.id,
        'userData': userData,
      };

    } catch (e) {
      print('❌ Login error: $e');
      throw Exception('Error signing in: $e');
    }
  }

  // Load current user data
  Future<void> _loadCurrentUserData() async {
    try {
      if (_currentUserId != null) {
        final doc = await _firestore.collection(_collection).doc(_currentUserId).get();
        if (doc.exists) {
          _currentUserData = doc.data();
        }
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
    }
  }

  // Save session to SharedPreferences
  Future<void> _saveSession(String userId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', userId);
    } catch (e) {
      print('❌ Error saving session: $e');
    }
  }

  // Clear session
  Future<void> _clearSession() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user_id');
    } catch (e) {
      print('❌ Error clearing session: $e');
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      await _clearSession();
      _currentUserId = null;
      _currentUserData = null;
      print('✅ Logout successful');
    } catch (e) {
      print('❌ Error during logout: $e');
      throw Exception('Error signing out: $e');
    }
  }

  // Get user data by ID
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('❌ Error getting user data: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String fullName,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      if (_currentUserId != null) {
        final updateData = {
          'fullName': fullName.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
        if (address != null) updateData['address'] = address;

        await _firestore.collection(_collection).doc(_currentUserId).update(updateData);

        // Update local data
        if (_currentUserData != null) {
          _currentUserData!.addAll(updateData);
        }

        print('✅ Profile updated successfully');
      }
    } catch (e) {
      print('❌ Error updating profile: $e');
      throw Exception('Error updating profile: $e');
    }
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (_currentUserId == null || _currentUserData == null) {
        throw Exception('User not logged in');
      }

      // Verify current password
      final currentHashedPassword = _hashPassword(currentPassword, _currentUserData!['email']);
      if (currentHashedPassword != _currentUserData!['password']) {
        throw Exception('Password lama salah');
      }

      // Hash new password
      final newHashedPassword = _hashPassword(newPassword, _currentUserData!['email']);

      // Update password
      await _firestore.collection(_collection).doc(_currentUserId).update({
        'password': newHashedPassword,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Password changed successfully');
    } catch (e) {
      print('❌ Error changing password: $e');
      throw Exception('Error changing password: $e');
    }
  }

  // Reset password (simplified - in real app, you'd send email)
  Future<void> resetPassword(String email) async {
    try {
      // Find user
      final userQuery = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email.toLowerCase())
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('Email tidak ditemukan');
      }

      // Generate temporary password
      final tempPassword = 'temp' + DateTime.now().millisecondsSinceEpoch.toString().substring(8);
      final hashedTempPassword = _hashPassword(tempPassword, email);

      // Update password
      await _firestore.collection(_collection).doc(userQuery.docs.first.id).update({
        'password': hashedTempPassword,
        'updatedAt': FieldValue.serverTimestamp(),
        'tempPassword': tempPassword, // Store temp password for demo (remove in production)
      });

      print('✅ Password reset. Temp password: $tempPassword');
      // In production, you'd send this via email
      throw Exception('Password reset berhasil. Password sementara: $tempPassword');
    } catch (e) {
      print('❌ Error resetting password: $e');
      rethrow;
    }
  }

  // Delete user by document ID (permanent deletion)
  Future<void> deleteUserById(String documentId) async {
    try {
      print('🔄 Deleting user permanently: $documentId');

      // Permanent deletion
      await _firestore.collection(_collection).doc(documentId).delete();

      print('✅ User permanently deleted: $documentId');
    } catch (e) {
      print('❌ Error deleting user: $e');
      throw Exception('Error deleting user: $e');
    }
  }

  // Get all users (HANYA SATU METHOD INI)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      print('🔄 Getting all active users from Firestore...');

      // Query sederhana - ambil semua user yang ada (tanpa where clause untuk menghindari index)
      final snapshot = await _firestore.collection(_collection).get();

      List<Map<String, dynamic>> users = snapshot.docs
          .map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id; // Add document ID untuk delete
        data.remove('password'); // Remove password
        return data;
      })
          .toList();

      // Sort by creation date (newest first)
      users.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        try {
          final aDate = (aTime as Timestamp).toDate();
          final bDate = (bTime as Timestamp).toDate();
          return bDate.compareTo(aDate);
        } catch (e) {
          return 0;
        }
      });

      print('✅ Found ${users.length} users');
      return users;
    } catch (e) {
      print('❌ Error getting users: $e');
      throw Exception('Error getting users: $e');
    }
  }

  // Delete user account (untuk self-delete)
  Future<void> deleteAccount() async {
    try {
      if (_currentUserId != null) {
        // Permanent delete
        await _firestore.collection(_collection).doc(_currentUserId).delete();

        await logout();
        print('✅ Account deleted successfully');
      }
    } catch (e) {
      print('❌ Error deleting account: $e');
      throw Exception('Error deleting account: $e');
    }
  }
}