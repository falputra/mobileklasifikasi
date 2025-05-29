import 'package:cloud_firestore/cloud_firestore.dart';

class WeaponService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'weapons';
  bool _initialized = false;

  // Method untuk menambah senjata baru
  Future<void> addWeapon(Map<String, dynamic> weaponData) async {
    try {
      await _firestore.collection(_collection).add(weaponData);
      print('✅ Weapon added successfully');
    } catch (e) {
      print('❌ Error adding weapon: $e');
      throw Exception('Gagal menambahkan senjata: $e');
    }
  }

  // Method untuk mengupdate senjata yang sudah ada
  Future<void> updateWeapon(String weaponId, Map<String, dynamic> weaponData) async {
    try {
      await _firestore.collection(_collection).doc(weaponId).update(weaponData);
      print('✅ Weapon updated successfully');
    } catch (e) {
      print('❌ Error updating weapon: $e');
      throw Exception('Gagal memperbarui senjata: $e');
    }
  }

  // Method untuk mendapatkan stream weapons
  Stream<List<Map<String, dynamic>>> getWeapons() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Tambahkan ID dokumen
        return data;
      }).toList();
    });
  }

  // Method untuk mendapatkan senjata berdasarkan ID
  Future<Map<String, dynamic>?> getWeaponById(String weaponId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(weaponId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('❌ Error getting weapon: $e');
      throw Exception('Gagal mengambil data senjata: $e');
    }
  }

  // Method untuk menghapus senjata
  Future<void> deleteWeapon(String weaponId) async {
    try {
      await _firestore.collection(_collection).doc(weaponId).delete();
      print('✅ Weapon deleted successfully');
    } catch (e) {
      print('❌ Error deleting weapon: $e');
      throw Exception('Gagal menghapus senjata: $e');
    }
  }

  // Method untuk search senjata berdasarkan nama dan lokasi
  Future<List<Map<String, dynamic>>> searchWeapons(String query) async {
    try {
      // Ambil semua data senjata
      final snapshot = await _firestore.collection(_collection).get();

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

      return results;
    } catch (e) {
      print('❌ Error searching weapons by criteria: $e');
      throw Exception('Gagal mencari senjata berdasarkan kriteria: $e');
    }
  }

  // Method untuk inisialisasi data sample (hanya sekali)
  Future<void> initializeSampleData() async {
    if (_initialized) return;

    try {
      // Cek apakah sudah ada data
      final snapshot = await _firestore.collection(_collection).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        _initialized = true;
        return;
      }

      // Data sample senjata tradisional Jawa Barat
      final sampleWeapons = [
        {
          'name': 'Kujang',
          'image': 'images/kujang.png',
          'origin': 'Jawa Barat',
          'description': 'Kujang adalah senjata tradisional khas Jawa Barat yang memiliki bentuk unik menyerupai bulan sabit. Senjata ini tidak hanya berfungsi sebagai alat perang, tetapi juga memiliki nilai spiritual dan filosofis yang tinggi dalam budaya Sunda.',
          'usage': 'Digunakan sebagai senjata perang, alat pertanian, dan simbol kekuasaan. Dalam kehidupan sehari-hari, kujang juga digunakan untuk memotong kayu dan bambu.',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Bedog',
          'image': 'images/bedog.png',
          'origin': 'Jawa Barat',
          'description': 'Bedog adalah golok besar yang digunakan oleh masyarakat Sunda. Bentuknya yang lebar dan berat membuatnya sangat efektif untuk berbagai keperluan. Bedog memiliki gagang yang kuat dan mata pisau yang tajam.',
          'usage': 'Digunakan untuk memotong kayu, membersihkan lahan, dan sebagai senjata untuk pertahanan diri. Juga digunakan dalam upacara adat tertentu.',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Golok',
          'image': 'images/golok.jpg',
          'origin': 'Jawa Barat',
          'description': 'Golok adalah pisau besar yang umum digunakan di Jawa Barat. Memiliki mata pisau yang lebar dan tajam dengan gagang yang ergonomis. Golok merupakan alat yang sangat praktis dalam kehidupan sehari-hari masyarakat Sunda.',
          'usage': 'Digunakan untuk keperluan dapur, pertanian, dan sebagai alat potong serba guna. Juga dapat digunakan sebagai senjata untuk pertahanan diri.',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Patik',
          'image': 'images/patik.webp',
          'origin': 'Jawa Barat',
          'description': 'Patik adalah senjata tradisional berupa pisau kecil yang digunakan oleh masyarakat Sunda. Meskipun berukuran kecil, patik memiliki ketajaman yang luar biasa dan mudah dibawa kemana-mana.',
          'usage': 'Digunakan sebagai alat potong kecil, pisau saku, dan untuk keperluan sehari-hari yang membutuhkan alat tajam berukuran kecil.',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Congkrang',
          'image': 'images/congkrang.webp',
          'origin': 'Jawa Barat',
          'description': 'Congkrang adalah senjata tradisional yang memiliki bentuk unik dengan mata pisau yang melengkung. Senjata ini memiliki fungsi ganda sebagai alat dan senjata, dengan desain yang memudahkan penggunaan.',
          'usage': 'Digunakan untuk memotong tumbuhan, sebagai alat pertanian, dan dapat dijadikan senjata untuk pertahanan diri dalam situasi darurat.',
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      // Tambahkan data sample ke Firestore
      for (final weapon in sampleWeapons) {
        await addWeapon(weapon);
      }

      _initialized = true;
      print('✅ Sample data initialized successfully');
    } catch (e) {
      print('❌ Error initializing sample data: $e');
    }
  }

  // Method untuk mendapatkan jumlah total senjata
  Future<int> getTotalWeaponsCount() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error getting weapons count: $e');
      return 0;
    }
  }

  // Method untuk mendapatkan senjata berdasarkan origin
  Stream<List<Map<String, dynamic>>> getWeaponsByOrigin(String origin) {
    return _firestore
        .collection(_collection)
        .where('origin', isEqualTo: origin)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}