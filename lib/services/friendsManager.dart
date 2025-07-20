import 'package:cloud_firestore/cloud_firestore.dart';

class FriendsManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Envoie une demande d'ami
  Future<void> sendFriendRequest(String myUserId, String friendUserId) async {
    final myDoc = _firestore.collection('users').doc(myUserId);
    final friendDoc = _firestore.collection('users').doc(friendUserId);

    final mySnapshot = await myDoc.get();
    final friendSnapshot = await friendDoc.get();

    final sentRequests = List<String>.from(mySnapshot.data()?['friendRequestSent'] ?? []);
    final receivedRequests = List<String>.from(friendSnapshot.data()?['friendRequestsReceived'] ?? []);

    // Vérifie si la demande existe déjà
    if (sentRequests.contains(friendUserId)  || receivedRequests.contains(myUserId)) {
      throw Exception('Demande déjà envoyée.');
    }

    await myDoc.update({
      'friendRequestSent': FieldValue.arrayUnion([friendUserId]),
    });

    await friendDoc.update({
      'friendRequestsReceived': FieldValue.arrayUnion([myUserId]),
    });
  }

  /// Accepte une demande d'ami
  Future<void> acceptFriendRequest(String myUserId, String friendUserId) async {
    final myDocRef = _firestore.collection('users').doc(myUserId);
    final friendDocRef = _firestore.collection('users').doc(friendUserId);

    await _firestore.runTransaction((transaction) async {

      transaction.update(myDocRef, {
        'friends': FieldValue.arrayUnion([friendUserId]),
        'friendRequestsReceived': FieldValue.arrayRemove([friendUserId]),
      });

      transaction.update(friendDocRef, {
        'friends': FieldValue.arrayUnion([myUserId]),
        'friendRequestsSent': FieldValue.arrayRemove([myUserId]),
      });
    });
  }

  /// Refuse une demande d'ami
  Future<void> declineFriendRequest(String myUserId, String friendUserId) async {
    final myDocRef = _firestore.collection('users').doc(myUserId);
    final friendDocRef = _firestore.collection('users').doc(friendUserId);

    await _firestore.runTransaction((transaction) async {
      final mySnap = await transaction.get(myDocRef);
      final friendSnap = await transaction.get(friendDocRef);

      if (!mySnap.exists) throw Exception("Mon profil n'existe pas");
      if (!friendSnap.exists) throw Exception("Profil ami n'existe pas");

      final myData = mySnap.data()!;
      final friendData = friendSnap.data()!;

      final myReceived = List<String>.from(myData['friendRequestsReceived'] ?? []);
      final friendSent = List<String>.from(friendData['friendRequestsSent'] ?? []);

      myReceived.remove(friendUserId);
      friendSent.remove(myUserId);

      transaction.update(myDocRef, {'friendRequestsReceived': myReceived});
      transaction.update(friendDocRef, {'friendRequestsSent': friendSent});
    });
  }

  /// Retirer un ami
  Future<void> removeFriend(String myUserId, String friendUserId) async {
    final myDocRef = _firestore.collection('users').doc(myUserId);
    final friendDocRef = _firestore.collection('users').doc(friendUserId);

    await _firestore.runTransaction((transaction) async {
      final mySnap = await transaction.get(myDocRef);
      final friendSnap = await transaction.get(friendDocRef);

      if (!mySnap.exists || !friendSnap.exists) return;

      final myFriends = List<String>.from(mySnap.data()!['friends'] ?? []);
      final friendFriends = List<String>.from(friendSnap.data()!['friends'] ?? []);

      myFriends.remove(friendUserId);
      friendFriends.remove(myUserId);

      transaction.update(myDocRef, {'friends': myFriends});
      transaction.update(friendDocRef, {'friends': friendFriends});
    });
  }

  /// Annuler une demande envoyée : supprime dans 'friendRequestSent' et 'friendRequestsReceived'
  Future<void> cancelFriendRequest({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final myDocRef = _firestore.collection('users').doc(currentUserId);
    final otherDocRef = _firestore.collection('users').doc(otherUserId);

    await _firestore.runTransaction((transaction) async {
      transaction.update(myDocRef, {
        'friendRequestSent': FieldValue.arrayRemove([otherUserId]),
      });
      transaction.update(otherDocRef, {
        'friendRequestsReceived': FieldValue.arrayRemove([currentUserId]),
      });
    });
  }
}
