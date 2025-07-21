import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chatService.dart';
import 'chatScreen.dart';
import 'friendsListScreen.dart';

class ConversationsScreen extends StatelessWidget {
  final ChatService logic = ChatService();

  ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: logic.getConversationsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final conversations = snapshot.data!;
          if (conversations.isEmpty) {
            return const Center(child: Text('Aucune conversation'));
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final conversationId = conversation['conversationId'] as String;
              final lastMessage = conversation['lastMessage'] ?? '';

              return ListTile(
                leading: FutureBuilder<Map<String, dynamic>>(
                  future: logic.getUserInfo(
                    (conversation['participants'] as List).firstWhere((id) => id != FirebaseAuth.instance.currentUser?.uid),
                  ),
                  builder: (context, userSnapshot) {
                    final profilePictureUrl = userSnapshot.data?['profilePictureUrl'] as String? ?? 'https://via.placeholder.com/150';
                    return CircleAvatar(
                      backgroundImage: NetworkImage(profilePictureUrl),
                    );
                  },
                ),
                title: FutureBuilder<Map<String, dynamic>>(
                  future: logic.getUserInfo(
                    (conversation['participants'] as List).firstWhere((id) => id != FirebaseAuth.instance.currentUser?.uid),
                  ),
                  builder: (context, userSnapshot) {
                    final username = userSnapshot.data?['username'] ?? 'Utilisateur';
                    return Text(username);
                  },
                ),
                subtitle: Text(lastMessage.isEmpty ? 'Aucun message' : lastMessage),
                trailing: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('conversations')
                      .doc(conversation['conversationId'])
                      .collection('messages')
                      .where('senderId', isNotEqualTo: FirebaseAuth.instance.currentUser?.uid)
                      .where('isRead', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
                    return CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red,
                      child: Text(
                        snapshot.data!.docs.length.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    );
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(conversationId: conversationId),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FriendsListScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}