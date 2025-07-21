import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/chatModel.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class ChatService {
  // Récupérer la liste des conversations de l'utilisateur connecté
  Stream<List<Map<String, dynamic>>> getConversationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
      ...doc.data(),
      'conversationId': doc.id,
    }).toList());
  }

  // Récupérer les messages d'une conversation
  Stream<List<ChatModel>> getMessagesStream(String conversationId) {
    return FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Envoyer un message
  Future<void> sendMessage(String conversationId, String content) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || content.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add({
      'conversationId': conversationId,
      'senderId': user.uid,
      'content': content,
      'createdAt': Timestamp.now(),
      'isRead': false,
    });

    // Mettre à jour la dernière activité de la conversation
    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .update({
      'lastMessage': content,
      'lastMessageAt': Timestamp.now(),
    });

    // Envoyer une notification locale pour l'autre utilisateur
    final otherUserId = (await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .get())
        .data()?['participants']
        .firstWhere((id) => id != user.uid);

    if (otherUserId != null) {
      await flutterLocalNotificationsPlugin.show(
        0,
        'Nouveau message',
        content,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'message_channel',
            'Messages',
            importance: Importance.high,
          ),
        ),
      );
    }
  }

  // Créer une nouvelle conversation
  Future<String?> createConversation(String recipientId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || recipientId.isEmpty) return null;

    // Vérifier si une conversation existe déjà
    final querySnapshot = await FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: user.uid)
        .get();

    for (var doc in querySnapshot.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.contains(recipientId)) {
        return doc.id; // Conversation existante
      }
    }

    // Créer une nouvelle conversation
    final docRef = await FirebaseFirestore.instance.collection('conversations').add({
      'participants': [user.uid, recipientId],
      'lastMessage': '',
      'lastMessageAt': Timestamp.now(),
      'createdAt': Timestamp.now(),
    });

    return docRef.id;
  }

  // Marquer les messages non lus comme lus
  Future<void> markMessagesAsRead(String conversationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('senderId', isNotEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in querySnapshot.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  // Récupérer les informations d'un utilisateur
  Future<Map<String, dynamic>> getUserInfo(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data() ?? {};
  }
}