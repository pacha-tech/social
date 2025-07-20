import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/friendsManager.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchFriendsScreen extends StatefulWidget {
  const SearchFriendsScreen({super.key});

  @override
  State<SearchFriendsScreen> createState() => _SearchFriendsScreenState();
}

class _SearchFriendsScreenState extends State<SearchFriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final results = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    setState(() {
      _searchResults = results.docs
          .map((doc) => {
            'uid': doc.id,
            'username': doc['username'],
            //'photoUrl': doc['photoUrl'] ?? '',
      })
          .toList();
      _isLoading = false;
    });
  }

  final FriendsManager _friendsManager = FriendsManager();

  void _sendFriendRequest(String friendUid) async{
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    try {
      await _friendsManager.sendFriendRequest(myUid, friendUid);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande envoyée !')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechercher des amis'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher un ami...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchUsers,
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_searchResults.isEmpty)
              const Text('Aucune résultat.')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey[200],
                        child: ClipOval(
                          child: user['photoUrl'] != null && user['photoUrl'].isNotEmpty
                              ? CachedNetworkImage(
                            imageUrl: user['photoUrl'],
                            width: 48, // même taille que ton radius * 2
                            height: 48,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) => const Icon(Icons.person),
                          )
                              : const Icon(Icons.person, size: 32 , color: Colors.red),
                        ),
                      ),
                      title: Text(user['username']),
                      trailing: ElevatedButton(
                        onPressed: () => _sendFriendRequest(user['uid']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Envoyer'),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
