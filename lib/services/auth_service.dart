import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw Exception('Format email tidak valid');
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('Register berhasil!');

      // Update display name
      await result.user?.updateDisplayName(fullName);

      // Save user data to Firestore
      await _firestore.collection('users').doc(result.user?.uid).set({
        'uid': result.user?.uid,
        'email': email,
        'fullName': fullName,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return result;
    } on FirebaseAuthException catch (e) {
      print('Error register: $e');
      throw _handleAuthException(e);
    } catch (e) {
      print('Error register: $e');
      throw Exception('Error creating account: $e');
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('Login berhasil!');

      // Update last login
      await _firestore.collection('users').doc(result.user?.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return result;
    } on FirebaseAuthException catch (e) {
      print('Error login: $e');
      throw _handleAuthException(e);
    } catch (e) {
      print('Error login: $e');
      throw Exception('Error signing in: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('Logout berhasil!');
    } catch (e) {
      print('Error logout: $e');
      throw Exception('Error signing out: $e');
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUser != null) {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .get();

        if (doc.exists) {
          return doc.data() as Map<String, dynamic>?;
        }
      }
      return null;
    } catch (e) {
      print('Error get user data: $e');
      throw Exception('Error getting user data: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String fullName,
  }) async {
    try {
      if (currentUser != null) {
        await currentUser!.updateDisplayName(fullName);
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'fullName': fullName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('Update profile berhasil!');
      }
    } catch (e) {
      print('Error update profile: $e');
      throw Exception('Error updating profile: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Reset password berhasil!');
    } on FirebaseAuthException catch (e) {
      print('Error reset password: $e');
      throw _handleAuthException(e);
    } catch (e) {
      print('Error reset password: $e');
      throw Exception('Error sending reset email: $e');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password terlalu lemah';
      case 'email-already-in-use':
        return 'Email sudah digunakan';
      case 'user-not-found':
        return 'User  tidak ditemukan';
      case 'wrong-password':
        return 'Password salah';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'user-disabled':
        return 'Akun telah dinonaktifkan';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan, coba lagi nanti';
      default:
        return 'Terjadi kesalahan: ${e.message}';
    }
  }
}