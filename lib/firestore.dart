import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference notes = FirebaseFirestore.instance.collection(
    'notes',
  );
  final CollectionReference users = FirebaseFirestore.instance.collection(
    'users',
  );
  final CollectionReference farmerPosts = FirebaseFirestore.instance.collection(
    'farmer_posts',
  );

  // ---------------- Notes ----------------

  Future<void> addNote(String note) {
    return notes.add({'note': note, 'timestamp': Timestamp.now()});
  }

  Stream<QuerySnapshot> getNotesSteam() {
    return notes.orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> updateNote(String docId, String docNote) {
    return notes.doc(docId).update({
      'note': docNote,
      'timestamp': Timestamp.now(),
    });
  }

  Future<void> deleteNote(String docId) {
    return notes.doc(docId).delete();
  }

  // ---------------- User Auth ----------------

  Future<bool> loginUser(String email, String password) async {
    final result = await users
        .where('email', isEqualTo: email)
        .where('password', isEqualTo: password)
        .get();

    return result.docs.isNotEmpty;
  }

  Future<void> createUser(
    String name,
    String email,
    String password,
    String userType,
  ) {
    return users.add({
      'name': name,
      'email': email,
      'password': password,
      'user_type': userType,
      'created_at': Timestamp.now(),
    });
  }

  Future<bool> checkEmailExists(String email) async {
    final result = await users.where('email', isEqualTo: email).get();
    return result.docs.isNotEmpty;
  }

  // ---------------- Farmer Posts ----------------

  Future<void> addFarmerPost({
    required String userEmail,
    required String category,
    required String riceType,
    required String price,
    required String productType,
    required String description,
    String?
    imagePath, // This will store local image path only (e.g. from ImagePicker)
  }) {
    return farmerPosts.add({
      'user_email': userEmail,
      'category': category,
      'rice_type': riceType,
      'price': price,
      'product_type': productType,
      'description': description,
      'image_path': imagePath, // Save local file path
      'created_at': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getFarmerPosts(String userEmail) {
    return farmerPosts
        .where('user_email', isEqualTo: userEmail)
        .orderBy('created_at', descending: true)
        .snapshots();
  }
}
