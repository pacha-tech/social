import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Inscription
  Future<User?> signUpWithEmailAndPassword(
      String email,
      String password,
      String username,
      String city,
      String bio,
      String birthdateString,
      ) async {
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = result.user;

    if (user != null) {
      // 🔑 Mets à jour le displayName pour Auth
      //await user.updateDisplayName(username);
      //await user.reload();

      DateTime birthdate = DateTime.parse(birthdateString);

      Timestamp birthdateTimestamp = Timestamp.fromDate(birthdate);

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'username': username,
        'city': city,
        'bio': bio,
        'birthdate': birthdateTimestamp,
        'profilePictureUrl': '',
        'friends': [],
        'friendRequestSent': [],
        'friendRequestsReceived': [],
      });
    }

    return user;
  }

  // 🔹 Connexion
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, password: password);

    return result.user;
  }

  // 🔹 Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
