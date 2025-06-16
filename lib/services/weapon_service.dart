import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class WeaponService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'weapons';
  bool _initialized = false;

  // Method untuk menambah senjata baru
  Future<void> addWeapon(Map<String, dynamic> weaponData) async {
    try {
      print('🔄 Adding weapon to Firestore...');

      // Pastikan data memiliki timestamp
      weaponData['createdAt'] = FieldValue.serverTimestamp();
      weaponData['updatedAt'] = FieldValue.serverTimestamp();

      DocumentReference docRef = await _firestore.collection(_collection).add(weaponData);

      print('✅ Weapon added successfully with ID: ${docRef.id}');
      print('📄 Weapon data: ${weaponData.toString()}');
    } catch (e) {
      print('❌ Error adding weapon: $e');
      throw Exception('Gagal menambahkan senjata: $e');
    }
  }

  // Method untuk mengupdate senjata yang sudah ada
  Future<void> updateWeapon(String weaponId, Map<String, dynamic> weaponData) async {
    try {
      print('🔄 Updating weapon ID: $weaponId');

      // Tambahkan timestamp update
      weaponData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(_collection).doc(weaponId).update(weaponData);

      print('✅ Weapon updated successfully');
    } catch (e) {
      print('❌ Error updating weapon: $e');
      throw Exception('Gagal memperbarui senjata: $e');
    }
  }

  // Method untuk mendapatkan stream weapons
  Stream<List<Map<String, dynamic>>> getWeapons() {
    print('🔄 Getting weapons stream from Firestore...');

    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print('📡 Received ${snapshot.docs.length} weapons from stream');

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Tambahkan ID dokumen

        // Debug log untuk setiap weapon
        print('📄 Weapon: ${data['name']} - Image: ${data['image']}');

        return data;
      }).toList();
    }).handleError((error) {
      print('❌ Error in weapons stream: $error');
      throw Exception('Error getting weapons stream: $error');
    });
  }

  // Method untuk mendapatkan senjata berdasarkan ID
  Future<Map<String, dynamic>?> getWeaponById(String weaponId) async {
    try {
      print('🔄 Getting weapon by ID: $weaponId');

      final doc = await _firestore.collection(_collection).doc(weaponId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        print('✅ Weapon found: ${data['name']}');
        return data;
      } else {
        print('⚠️ Weapon not found with ID: $weaponId');
        return null;
      }
    } catch (e) {
      print('❌ Error getting weapon: $e');
      throw Exception('Gagal mengambil data senjata: $e');
    }
  }

  // Method untuk menghapus senjata (termasuk gambar di Storage)
  Future<void> deleteWeapon(String weaponId) async {
    try {
      print('🔄 Deleting weapon ID: $weaponId');

      // Ambil data weapon terlebih dahulu untuk mendapatkan URL gambar
      final weaponDoc = await _firestore.collection(_collection).doc(weaponId).get();

      if (weaponDoc.exists) {
        final weaponData = weaponDoc.data() as Map<String, dynamic>;
        final imageUrl = weaponData['image'] as String?;

        // Hapus gambar dari Firebase Storage jika ada dan merupakan URL Firebase
        if (imageUrl != null && imageUrl.isNotEmpty && imageUrl.contains('firebase')) {
          await _deleteImageFromStorage(imageUrl);
        }

        // Hapus dokumen dari Firestore
        await _firestore.collection(_collection).doc(weaponId).delete();

        print('✅ Weapon deleted successfully');
      } else {
        throw Exception('Weapon not found');
      }
    } catch (e) {
      print('❌ Error deleting weapon: $e');
      throw Exception('Gagal menghapus senjata: $e');
    }
  }

  // Helper method untuk menghapus gambar dari Firebase Storage
  Future<void> _deleteImageFromStorage(String imageUrl) async {
    try {
      print('🔄 Deleting image from Storage: $imageUrl');

      // Extract path dari URL Firebase Storage
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();

      print('✅ Image deleted from Storage');
    } catch (e) {
      print('⚠️ Error deleting image from Storage (might not exist): $e');
      // Don't throw error here as the main deletion can still proceed
    }
  }

  // Method untuk search senjata berdasarkan nama dan lokasi
  Future<List<Map<String, dynamic>>> searchWeapons(String query) async {
    try {
      print('🔍 Searching weapons with query: $query');

      // Ambil semua data senjata
      final snapshot = await _firestore.collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      // Filter data berdasarkan query (nama atau lokasi)
      final allWeapons = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Lakukan pencarian lokal untuk nama dan lokasi
      final filteredWeapons = allWeapons.where((weapon) {
        final name = (weapon['name'] ?? '').toString().toLowerCase();
        final origin = (weapon['origin'] ?? '').toString().toLowerCase();
        final description = (weapon['description'] ?? '').toString().toLowerCase();
        final usage = (weapon['usage'] ?? '').toString().toLowerCase();
        final searchQuery = query.toLowerCase();

        // Cari di nama, lokasi, deskripsi, dan kegunaan
        return name.contains(searchQuery) ||
            origin.contains(searchQuery) ||
            description.contains(searchQuery) ||
            usage.contains(searchQuery);
      }).toList();

      // Urutkan hasil berdasarkan relevansi (nama > lokasi > deskripsi > kegunaan)
      filteredWeapons.sort((a, b) {
        final nameA = (a['name'] ?? '').toString().toLowerCase();
        final nameB = (b['name'] ?? '').toString().toLowerCase();
        final originA = (a['origin'] ?? '').toString().toLowerCase();
        final originB = (b['origin'] ?? '').toString().toLowerCase();
        final searchQuery = query.toLowerCase();

        // Prioritas: nama exact match > nama contains > origin exact match > origin contains
        if (nameA == searchQuery) return -1;
        if (nameB == searchQuery) return 1;
        if (nameA.startsWith(searchQuery) && !nameB.startsWith(searchQuery)) return -1;
        if (nameB.startsWith(searchQuery) && !nameA.startsWith(searchQuery)) return 1;
        if (originA == searchQuery) return -1;
        if (originB == searchQuery) return 1;

        // Default sort by name
        return nameA.compareTo(nameB);
      });

      print('✅ Search completed. Found ${filteredWeapons.length} results');
      return filteredWeapons;
    } catch (e) {
      print('❌ Error searching weapons: $e');
      throw Exception('Gagal mencari senjata: $e');
    }
  }

  // Method untuk search berdasarkan multiple criteria
  Future<List<Map<String, dynamic>>> searchWeaponsByCriteria({
    String? name,
    String? origin,
    String? description,
  }) async {
    try {
      print('🔍 Searching weapons by criteria - Name: $name, Origin: $origin, Description: $description');

      Query query = _firestore.collection(_collection);

      // Tambahkan filter berdasarkan criteria yang diberikan
      if (name != null && name.isNotEmpty) {
        query = query.where('name', isGreaterThanOrEqualTo: name)
            .where('name', isLessThanOrEqualTo: name + '\uf8ff');
      }

      if (origin != null && origin.isNotEmpty) {
        query = query.where('origin', isEqualTo: origin);
      }

      final snapshot = await query.get();

      List<Map<String, dynamic>> results = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Filter tambahan untuk deskripsi jika diperlukan
      if (description != null && description.isNotEmpty) {
        results = results.where((weapon) {
          final weaponDesc = (weapon['description'] ?? '').toString().toLowerCase();
          return weaponDesc.contains(description.toLowerCase());
        }).toList();
      }

      print('✅ Criteria search completed. Found ${results.length} results');
      return results;
    } catch (e) {
      print('❌ Error searching weapons by criteria: $e');
      throw Exception('Gagal mencari senjata berdasarkan kriteria: $e');
    }
  }

  // Method untuk mendapatkan jumlah total senjata
  Future<int> getTotalWeaponsCount() async {
    try {
      print('🔄 Getting total weapons count...');

      final snapshot = await _firestore.collection(_collection).get();
      final count = snapshot.docs.length;

      print('✅ Total weapons count: $count');
      return count;
    } catch (e) {
      print('❌ Error getting weapons count: $e');
      return 0;
    }
  }

  // Method untuk mendapatkan senjata berdasarkan origin
  Stream<List<Map<String, dynamic>>> getWeaponsByOrigin(String origin) {
    print('🔄 Getting weapons by origin: $origin');

    return _firestore
        .collection(_collection)
        .where('origin', isEqualTo: origin)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print('📡 Received ${snapshot.docs.length} weapons from origin: $origin');

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Method untuk mendapatkan list origin yang unik
  Future<List<String>> getUniqueOrigins() async {
    try {
      print('🔄 Getting unique origins...');

      final snapshot = await _firestore.collection(_collection).get();
      final origins = snapshot.docs
          .map((doc) => (doc.data()['origin'] ?? '').toString())
          .where((origin) => origin.isNotEmpty)
          .toSet()
          .toList();

      origins.sort();

      print('✅ Found ${origins.length} unique origins');
      return origins;
    } catch (e) {
      print('❌ Error getting unique origins: $e');
      return [];
    }
  }

  // Method untuk menghapus semua weapons (untuk testing/development)
  Future<void> deleteAllWeapons() async {
    try {
      print('🔄 Deleting all weapons...');

      final snapshot = await _firestore.collection(_collection).get();

      // Delete semua dokumen
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      print('✅ All weapons deleted successfully. Count: ${snapshot.docs.length}');
    } catch (e) {
      print('❌ Error deleting all weapons: $e');
      throw Exception('Gagal menghapus semua senjata: $e');
    }
  }

  // Method untuk backup weapons ke format JSON (untuk development)
  Future<List<Map<String, dynamic>>> backupWeapons() async {
    try {
      print('🔄 Creating weapons backup...');

      final snapshot = await _firestore.collection(_collection)
          .orderBy('createdAt', descending: false)
          .get();

      final weapons = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        // Convert Timestamp to String for JSON compatibility
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        if (data['updatedAt'] is Timestamp) {
          data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
        }

        return data;
      }).toList();

      print('✅ Backup created with ${weapons.length} weapons');
      return weapons;
    } catch (e) {
      print('❌ Error creating backup: $e');
      throw Exception('Gagal membuat backup: $e');
    }
  }

  // Method untuk restore weapons dari backup (untuk development)
  Future<void> restoreWeapons(List<Map<String, dynamic>> weaponsData) async {
    try {
      print('🔄 Restoring weapons from backup...');

      final batch = _firestore.batch();

      for (final weaponData in weaponsData) {
        // Remove ID untuk mencegah conflict
        weaponData.remove('id');

        // Convert String timestamp back to Timestamp
        if (weaponData['createdAt'] is String) {
          weaponData['createdAt'] = Timestamp.fromDate(DateTime.parse(weaponData['createdAt']));
        } else {
          weaponData['createdAt'] = FieldValue.serverTimestamp();
        }

        if (weaponData['updatedAt'] is String) {
          weaponData['updatedAt'] = Timestamp.fromDate(DateTime.parse(weaponData['updatedAt']));
        } else {
          weaponData['updatedAt'] = FieldValue.serverTimestamp();
        }

        final docRef = _firestore.collection(_collection).doc();
        batch.set(docRef, weaponData);
      }

      await batch.commit();

      print('✅ Weapons restored successfully. Count: ${weaponsData.length}');
    } catch (e) {
      print('❌ Error restoring weapons: $e');
      throw Exception('Gagal restore senjata: $e');
    }
  }

  // Method untuk validasi data weapon sebelum disimpan
  bool _validateWeaponData(Map<String, dynamic> weaponData) {
    final requiredFields = ['name', 'origin', 'description', 'usage'];

    for (final field in requiredFields) {
      if (!weaponData.containsKey(field) ||
          weaponData[field] == null ||
          weaponData[field].toString().trim().isEmpty) {
        print('❌ Validation failed: Missing or empty field: $field');
        return false;
      }
    }

    // Validasi panjang minimal
    if (weaponData['name'].toString().length < 2) {
      print('❌ Validation failed: Name too short');
      return false;
    }

    if (weaponData['description'].toString().length < 10) {
      print('❌ Validation failed: Description too short');
      return false;
    }

    print('✅ Weapon data validation passed');
    return true;
  }

  // Method untuk clean up data (remove empty/invalid records)
  Future<int> cleanupWeaponsData() async {
    try {
      print('🔄 Starting weapons data cleanup...');

      final snapshot = await _firestore.collection(_collection).get();
      int cleanedCount = 0;

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Check for invalid data
        bool shouldDelete = false;

        if (data['name'] == null || data['name'].toString().trim().isEmpty) {
          shouldDelete = true;
        }

        if (data['origin'] == null || data['origin'].toString().trim().isEmpty) {
          shouldDelete = true;
        }

        if (shouldDelete) {
          batch.delete(doc.reference);
          cleanedCount++;
          print('🗑️ Marked for deletion: ${doc.id} - ${data['name']}');
        }
      }

      if (cleanedCount > 0) {
        await batch.commit();
        print('✅ Cleanup completed. Removed $cleanedCount invalid records');
      } else {
        print('✅ No cleanup needed. All records are valid');
      }

      return cleanedCount;
    } catch (e) {
      print('❌ Error during cleanup: $e');
      throw Exception('Gagal membersihkan data: $e');
    }
  }

  // Method untuk get statistics
  Future<Map<String, dynamic>> getWeaponsStatistics() async {
    try {
      print('🔄 Getting weapons statistics...');

      final snapshot = await _firestore.collection(_collection).get();
      final weapons = snapshot.docs.map((doc) => doc.data()).toList();

      // Count by origin
      final Map<String, int> originCounts = {};
      for (final weapon in weapons) {
        final origin = weapon['origin']?.toString() ?? 'Unknown';
        originCounts[origin] = (originCounts[origin] ?? 0) + 1;
      }

      // Calculate dates
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thisWeek = today.subtract(Duration(days: 7));
      final thisMonth = DateTime(now.year, now.month, 1);

      int addedToday = 0;
      int addedThisWeek = 0;
      int addedThisMonth = 0;

      for (final weapon in weapons) {
        if (weapon['createdAt'] is Timestamp) {
          final createdDate = (weapon['createdAt'] as Timestamp).toDate();
          if (createdDate.isAfter(today)) addedToday++;
          if (createdDate.isAfter(thisWeek)) addedThisWeek++;
          if (createdDate.isAfter(thisMonth)) addedThisMonth++;
        }
      }

      final stats = {
        'totalWeapons': weapons.length,
        'originCounts': originCounts,
        'addedToday': addedToday,
        'addedThisWeek': addedThisWeek,
        'addedThisMonth': addedThisMonth,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      print('✅ Statistics generated: ${stats.toString()}');
      return stats;
    } catch (e) {
      print('❌ Error getting statistics: $e');
      return {};
    }
  }
}