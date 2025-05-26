import 'package:cloud_firestore/cloud_firestore.dart';

class WeaponService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'weapons';

  // Get all weapons with better error handling
  Stream<List<Map<String, dynamic>>> getWeapons() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: false) // Urutkan berdasarkan waktu dibuat
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Get weapons as Future (untuk satu kali ambil data)
  Future<List<Map<String, dynamic>>> getWeaponsOnce() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching weapons: $e');
    }
  }

  // Get single weapon by ID
  Future<Map<String, dynamic>?> getWeaponById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching weapon: $e');
    }
  }

  // Add new weapon
  Future<String> addWeapon(Map<String, dynamic> weaponData) async {
    try {
      // Tambahkan timestamp
      weaponData['createdAt'] = FieldValue.serverTimestamp();
      weaponData['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection(_collection).add(weaponData);
      return docRef.id;
    } catch (e) {
      throw Exception('Error adding weapon: $e');
    }
  }

  // Update weapon
  Future<void> updateWeapon(String id, Map<String, dynamic> weaponData) async {
    try {
      // Tambahkan timestamp update
      weaponData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(_collection).doc(id).update(weaponData);
    } catch (e) {
      throw Exception('Error updating weapon: $e');
    }
  }

  // Delete weapon
  Future<void> deleteWeapon(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Error deleting weapon: $e');
    }
  }

  // Search weapons by name
  Stream<List<Map<String, dynamic>>> searchWeapons(String query) {
    return _firestore
        .collection(_collection)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Get weapons count
  Future<int> getWeaponsCount() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Error getting weapons count: $e');
    }
  }

  // Check if collection exists and has data
  Future<bool> hasData() async {
    try {
      final snapshot = await _firestore.collection(_collection).limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Initialize with sample data (call this once)
  Future<void> initializeSampleData() async {
    try {
      // Check if data already exists
      final hasExistingData = await hasData();
      if (hasExistingData) {
        print('Sample data already exists, skipping initialization.');
        return;
      }

      final sampleWeapons = [
        {
          'name': 'Kujang',
          'image': 'images/kujang.png',
          'origin': 'Jawa Barat',
          'description': 'Kujang adalah senjata tradisional dari Jawa Barat yang berbentuk melengkung dengan ujung yang runcing. Bentuknya yang khas melambangkan keseimbangan alam dan kehidupan. Kujang memiliki nilai filosofis tinggi bagi masyarakat Sunda dan sering digunakan sebagai simbol identitas budaya.',
          'usage': 'Dahulu Kujang digunakan sebagai senjata perang dan alat pertanian. Namun sekarang lebih banyak digunakan sebagai hiasan atau benda pusaka. Kujang juga sering dijadikan simbol dalam lambang daerah di Jawa Barat.',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Bedog',
          'image': 'images/bedog.png',
          'origin': 'Jawa Barat',
          'description': 'Bedog adalah sejenis golok atau parang dari Jawa Barat yang memiliki bentuk pipih dan lebar. Bedog memiliki bilah yang tebal dan kokoh, dengan panjang sekitar 30-40 cm. Senjata ini memiliki gagang yang terbuat dari kayu atau tanduk.',
          'usage': 'Bedog terutama digunakan sebagai alat kerja untuk memotong, menebang, atau membelah benda keras seperti kayu. Selain itu, Bedog juga digunakan sebagai alat pertanian dan juga dapat berfungsi sebagai senjata untuk membela diri.',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Golok',
          'image': 'images/golok.jpg',
          'origin': 'Jawa Barat',
          'description': 'Golok adalah senjata tradisional berbentuk parang dengan bilah yang lebar dan tebal. Golok khas Jawa Barat memiliki bentuk yang sedikit melengkung pada bagian ujungnya. Sarungnya biasanya terbuat dari kayu dan diukir dengan motif-motif tradisional.',
          'usage': 'Golok digunakan untuk berbagai keperluan seperti membuka jalan di hutan, memotong kayu, sebagai alat pertanian, dan juga sebagai senjata untuk membela diri. Di beberapa daerah, Golok juga digunakan dalam upacara adat tertentu.',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Patik',
          'image': 'images/patik.webp',
          'origin': 'Jawa Barat',
          'description': 'Patik adalah senjata tajam tradisional dari Jawa Barat yang bentuknya mirip pisau kecil dengan bilah yang lurus dan tajam pada satu sisi. Ukurannya lebih kecil dari golok atau bedog. Patik memiliki gagang yang biasanya terbuat dari kayu atau tanduk.',
          'usage': 'Senjata ini digunakan untuk keperluan sehari-hari seperti mengolah hasil pertanian, memotong tali, dan pekerjaan halus lainnya. Selain itu, patik juga bisa digunakan sebagai senjata untuk membela diri dalam jarak dekat.',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Congkrang',
          'image': 'images/congkrang.webp',
          'origin': 'Jawa Barat',
          'description': 'Congkrang adalah senjata tradisional yang bentuknya mirip arit atau sabit dengan bilah melengkung dan tajam pada bagian dalamnya. Congkrang memiliki gagang yang biasanya terbuat dari kayu.',
          'usage': 'Senjata ini utamanya digunakan sebagai alat pertanian untuk memotong rumput, memanen padi, dan membersihkan semak belukar. Dalam situasi darurat, congkrang juga bisa digunakan sebagai senjata untuk membela diri.',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Ani-ani (Ketam)',
          'image': 'images/aniani.webp',
          'origin': 'Jawa Barat',
          'description': 'ani-ani atau ketam adalah alat tradisional yang digunakan khusus untuk memanen padi. Meskipun lebih tepat dikategorikan sebagai perkakas pertanian daripada senjata, ani-ani memiliki bagian tajam yang berbentuk seperti pisau kecil yang terpasang pada pegangan kayu.',
          'usage': 'Ani-ani digunakan dengan cara menggenggam batang padi dan memotongnya satu per satu, metode yang dianggap lebih menghormati Dewi Sri (dewi padi) dalam kepercayaan tradisional. Penggunaan ani-ani memungkinkan pemanenan yang selektif dan meminimalkan kerusakan tanaman.',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Sulimat',
          'image': 'images/sulimat.jpg',
          'origin': 'Jawa Barat',
          'description': 'Sulimat adalah senjata rahasia dari Jawa Barat yang bentuknya mirip dengan jarum atau pisau kecil yang sangat tajam. Ukurannya kecil sehingga mudah disembunyikan, biasanya di dalam pakaian atau aksesori.',
          'usage': 'Sulimat digunakan sebagai senjata tikam jarak dekat dalam situasi membela diri atau pertarungan. Karena ukurannya yang kecil, sulimat sering digunakan sebagai senjata rahasia atau cadangan oleh para pendekar tradisional.',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      // Add sample data
      for (var weapon in sampleWeapons) {
        await _firestore.collection(_collection).add(weapon);
      }

      print('Sample data initialized successfully!');
    } catch (e) {
      throw Exception('Error initializing sample data: $e');
    }
  }
}