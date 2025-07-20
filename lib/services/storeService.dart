import 'package:cloud_firestore/cloud_firestore.dart';

class StoreService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> createUserProfile({
    required String uid,
    required String email,
    required String displayName,
    required String city,
    required String dateOfBirth,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'city': city,
      'photoURL': '',
      'createdAt': FieldValue.serverTimestamp(),
      'dateOfBirth': dateOfBirth,
    });
  }
}
