import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();
  final _db = FirebaseFirestore.instance;

  /// users/{uid}
  CollectionReference<Map<String, dynamic>> get users =>
      _db.collection('users');

  /// Create or update user profile at users/{uid}
  Future<void> upsertUserProfile({
    required String uid,
    required String name,
    required String email,
    required String userType, // Farmer | Seller | Buyer | Admin
    String? photoUrl,
  }) async {
    final doc = users.doc(uid);
    await doc.set({
      'name': name,
      'email': email,
      'user_type': userType,
      'photo_url': photoUrl,
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get snapshot of users/{uid}
  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) {
    return users.doc(uid).get();
  }
}
