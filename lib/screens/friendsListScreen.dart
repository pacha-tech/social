import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chatService.dart';
import 'chatScreen.dart';

class FriendsListScreen extends StatelessWidget {
  final ChatService logic = ChatService();

  FriendsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Veuillez vous connecter')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes amis'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final friends = List<String>.from(userData?['friends'] ?? []);

          if (friends.isEmpty) {
            return const Center(child: Text('Vous n\'avez aucun ami ajouté'));
          }

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friendId = friends[index];

              return FutureBuilder<Map<String, dynamic>>(
                future: logic.getUserInfo(friendId),
                builder: (context, friendSnapshot) {
                  if (!friendSnapshot.hasData) {
                    return const ListTile(
                      title: Text('Chargement...'),
                    );
                  }

                  final friendData = friendSnapshot.data!;
                  final username = friendData['username'] ?? 'Utilisateur';

                  return ListTile(
                    title: Text(username),
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        friendData['profilePictureUrl'] ?? 'https://via.placeholder.com/150',
                      ),
                    ),
                    onTap: () async {
                      final conversationId = await logic.createConversation(friendId);
                      if (conversationId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(conversationId: conversationId),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}