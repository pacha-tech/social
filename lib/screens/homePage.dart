import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/myStoryCard.dart';
import 'package:social/screens/parameterScreen.dart';
import '../services/cloudinaryService.dart';
import 'searchFriendsScreen.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  Stream<List<Map<String, dynamic>>> getStoriesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('stories')
        .where('expireAt', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) {
      final allStories = snapshot.docs.map((doc) => {
        ...doc.data(),
        'docId': doc.id,
      }).toList();

      final myStories = allStories.where((story) => story['uid'] == user.uid).toList();
      final otherStories = allStories.where((story) => story['uid'] != user.uid).toList();

      otherStories.sort((a, b) {
        final aTs = a['createdAt'] as Timestamp?;
        final bTs = b['createdAt'] as Timestamp?;
        return (bTs?.compareTo(aTs!) ?? 0);
      });

      return [...myStories.take(1), ...otherStories];
    });
  }

  Future<String> getUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Utilisateur';

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.exists && doc.data()!.containsKey('username')
        ? doc['username'] as String
        : 'Utilisateur';
  }

  Future<String> getProfilePhotoUrl() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'https://via.placeholder.com/150';

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.exists && doc.data()!.containsKey('profilePictureUrl')
        ? doc['profilePictureUrl'] as String
        : 'https://via.placeholder.com/150';
  }

  Future<List<Map<String, dynamic>>> getMyStory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final querySnapshot = await FirebaseFirestore.instance
        .collection('stories')
        .where('uid', isEqualTo: user.uid)
        .where('expireAt', isGreaterThan: Timestamp.now())
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  void addStory(BuildContext context) async {
    final picker = ImagePicker();

    final String? mediaType = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Photo'),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Vidéo'),
              onTap: () => Navigator.pop(context, 'video'),
            ),
          ],
        );
      },
    );

    if (mediaType == null) return;

    List<XFile> files = [];
    if (mediaType == 'image') {
      files = await picker.pickMultiImage() ?? [];
    } else if (mediaType == 'video') {
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
      if (video != null) files = [video];
    }

    if (files.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    for (final file in files) {
      String? downloadUrl;
      if (mediaType == 'image') {
        downloadUrl = await uploadStoryImageToCloudinary(File(file.path), user.uid);
      } else if (mediaType == 'video') {
        downloadUrl = await uploadStoryVideoToCloudinary(File(file.path), user.uid);
      }

      if (downloadUrl != null) {
        final createdAt = Timestamp.now();
        final expireAt = Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24)));

        await FirebaseFirestore.instance.collection('stories').add({
          'uid': user.uid,
          'mediaUrl': downloadUrl,
          'type': mediaType, // ✅ corrigé
          'createdAt': createdAt,
          'expireAt': expireAt,
        });
      }
    }
  }

  Future<Map<String, dynamic>> getUserInfo(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchFriendsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ParameterScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔵 Titre + avatar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Posts récents',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      FutureBuilder<String>(
                        future: getUsername(),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data ?? 'Utilisateur',
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          );
                        },
                      ),
                    ],
                  ),
                  FutureBuilder<String>(
                    future: getProfilePhotoUrl(),
                    builder: (context, snapshot) {
                      final url = snapshot.data;
                      return CircleAvatar(
                        radius: 20,
                        backgroundImage: url != null && url.startsWith('http')
                            ? NetworkImage(url)
                            : null,
                        child: url == null || !url.startsWith('http')
                            ? const Icon(Icons.person)
                            : null,
                      );
                    },
                  ),
                ],
              ),
            ),

            // 🟢 Liste des stories
            SizedBox(
              height: 200,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: getStoriesStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final stories = snapshot.data!;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: stories.isEmpty ? 1 : stories.length,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return MyStoryCard(
                          getMyStory: getMyStory,
                          onAddStory: () async => addStory(context),
                        );
                      } else {
                        final story = stories[index];
                        final mediaUrl = story['mediaUrl'] ?? '';
                        final uid = story['uid'] ?? '';

                        return FutureBuilder<Map<String, dynamic>>(
                          future: getUserInfo(uid),
                          builder: (context, userSnapshot) {
                            final username = userSnapshot.data?['username'] ?? 'Utilisateur';
                            final profileUrl = userSnapshot.data?['profilePictureUrl'] ?? 'https://via.placeholder.com/150';

                            return Container(
                              width: 150,
                              margin: const EdgeInsets.only(left: 4),
                              child: Card(
                                elevation: 4,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Image.network(
                                        mediaUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => const Icon(Icons.person, size: 100),
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(top: 10, left: 10),
                                          child: CircleAvatar(
                                            radius: 30,
                                            backgroundImage: NetworkImage(profileUrl),
                                          ),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.only(top: 85, left: 10),
                                          child: Text(
                                            username,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // 🟢 Liste des posts
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 100,
              itemBuilder: (context, index) {
                return Container(
                  height: 400,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // Top bar
                      Expanded(
                        flex: 15,
                        child: Container(
                          color: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage('https://via.placeholder.com/150'),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Utilisateur #$index',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Main content
                      Expanded(
                        flex: 85,
                        child: Container(
                          color: Colors.white,
                          child: Center(
                            child: Text(
                              'Partie basse #$index',
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                      // Actions
                      Container(
                        height: 50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            Icon(Icons.favorite_border, color: Colors.green, size: 30),
                            Icon(Icons.message, color: Colors.green, size: 30),
                            Icon(Icons.share_rounded, color: Colors.green, size: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
