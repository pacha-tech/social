import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/friendsManager.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utilisateur non connecté");
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes Amis'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Amis'),
              Tab(text: 'Demandes reçues'),
              Tab(text: 'Demandes envoyées'),
            ],
          ),
        ),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: getUserStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Erreur'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data?.data();
            if (data == null) {
              return const Center(child: Text('Aucune donnée utilisateur'));
            }

            final friends = (data['friends'] as List<dynamic>?) ?? [];
            final requestsReceived = (data['friendRequestsReceived'] as List<dynamic>?) ?? [];
            final requestsSent = (data['friendRequestSent'] as List<dynamic>?) ?? [];

            return TabBarView(
              children: [
                FriendsTab(userIds: friends),
                RequestsReceivedTab(userIds: requestsReceived),
                RequestsSentTab(userIds: requestsSent),
              ],
            );
          },
        ),
      ),
    );
  }
}

// 🔥 Onglet 1 : Amis
class FriendsTab extends StatefulWidget {
  final List<dynamic> userIds;
  const FriendsTab({super.key, required this.userIds});

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 👈 Obligatoire

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.userIds.isEmpty) {
      return const Center(child: Text('Aucun ami pour l\'instant'));
    }
    return ListView.builder(
      itemCount: widget.userIds.length,
      itemBuilder: (context, index) {
        return UserTile(userId: widget.userIds[index]);
      },
    );
  }
}

// 🔥 Onglet 2 : Demandes reçues
class RequestsReceivedTab extends StatefulWidget {
  final List<dynamic> userIds;
  const RequestsReceivedTab({super.key, required this.userIds});

  @override
  State<RequestsReceivedTab> createState() => _RequestsReceivedTabState();
}

class _RequestsReceivedTabState extends State<RequestsReceivedTab>
    with AutomaticKeepAliveClientMixin {
  final friendsManager = FriendsManager();

  @override
  bool get wantKeepAlive => true; // 👈 Obligatoire

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = FirebaseAuth.instance.currentUser!;
    if (widget.userIds.isEmpty) {
      return const Center(child: Text('Aucune demande reçue'));
    }
    return ListView.builder(
      itemCount: widget.userIds.length,
      itemBuilder: (context, index) {
        final friendId = widget.userIds[index];
        return UserTile(
          userId: friendId,
          onAccept: () async {
            await friendsManager.acceptFriendRequest(user.uid, friendId);
          },
          onCancel: () async {
            await friendsManager.declineFriendRequest(user.uid, friendId);
          },
        );
      },
    );
  }
}

// 🔥 Onglet 3 : Demandes envoyées
class RequestsSentTab extends StatefulWidget {
  final List<dynamic> userIds;
  const RequestsSentTab({super.key, required this.userIds});

  @override
  State<RequestsSentTab> createState() => _RequestsSentTabState();
}

class _RequestsSentTabState extends State<RequestsSentTab>
    with AutomaticKeepAliveClientMixin {
  final friendsManager = FriendsManager();

  @override
  bool get wantKeepAlive => true; // 👈 Obligatoire

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = FirebaseAuth.instance.currentUser!;
    if (widget.userIds.isEmpty) {
      return const Center(child: Text('Aucune demande envoyée'));
    }
    return ListView.builder(
      itemCount: widget.userIds.length,
      itemBuilder: (context, index) {
        final friendId = widget.userIds[index];
        return UserTile(
          userId: friendId,
          onCancel: () async {
            await friendsManager.cancelFriendRequest(
              currentUserId: user.uid,
              otherUserId: friendId,
            );
          },
        );
      },
    );
  }
}

// 🔗 Widget UserTile réutilisable
class UserTile extends StatelessWidget {
  final String userId;
  final VoidCallback? onAccept;
  final VoidCallback? onCancel;

  const UserTile({
    super.key,
    required this.userId,
    this.onAccept,
    this.onCancel,
  });

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    return snapshot.data();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: getUserProfile(userId),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        final username = userData?['username'] ?? 'Utilisateur sans nom';
        final profilePictureUrl = userData?['profilePictureUrl'];

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: profilePictureUrl != null
                ? NetworkImage(profilePictureUrl)
                : null,
            child: profilePictureUrl == null
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(username),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onAccept != null)
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: onAccept,
                ),
              if (onCancel != null)
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: onCancel,
                ),
            ],
          ),
        );
      },
    );
  }
}
