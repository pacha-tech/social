import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../widgets/myStoryCard.dart';
import 'parameterScreen.dart';
import 'searchFriendsScreen.dart';
import '../services/homePageLogic.dart';
import '../widgets/storyViewer.dart';

class HomePage extends StatelessWidget {
  final HomePageLogic logic = HomePageLogic();

  HomePage({super.key});

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
                        future: logic.getUsername(),
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
                    future: logic.getProfilePhotoUrl(),
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
                stream: logic.getStoriesStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final stories = snapshot.data!;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: stories.length,
                    itemBuilder: (context, index) {
                      final story = stories[index];
                      final uid = story['uid'] ?? '';
                      final storyCount = story['storyCount'] ?? 0;

                      if (storyCount == 0) {
                        return MyStoryCard(
                          getMyStory: logic.getMyStory,
                          onAddStory: () async => logic.addStory(context),
                        );
                      } else {
                        //final story = stories[index];
                        //final uid = story['uid'] ?? '';

                        return FutureBuilder<Map<String, dynamic>>(
                          future: logic.getUserInfo(uid),
                          builder: (context, userSnapshot) {

                            if(!userSnapshot.hasData) return const SizedBox.shrink();

                            final username = userSnapshot.data?['username'] ?? 'Utilisateur';
                            final profileUrl = userSnapshot.data?['profilePictureUrl'] as String? ?? 'https://via.placeholder.com/150';
                            final mediaUrl = story['mediaUrl'] ?? '';

                            return GestureDetector(
                              onTap: () async {
                                final userStories = await logic.getUserStories(uid);
                                if(userStories.isNotEmpty){
                                  Navigator.push(
                                    context,
                                      MaterialPageRoute(
                                        builder: (context) => StoryViewer(
                                          stories: userStories,
                                          initialIndex: 0, // Commencer par la première story
                                        ),
                                      ),
                                  );
                                }
                              },
                              child: Container(
                                width: 150,
                                margin: const EdgeInsets.only(left: 4),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
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
                                      if(storyCount >= 1)
                                        Positioned(
                                          top: 5,
                                          right: 5,
                                          child: Container(
                                            width: 24, // Augmenté pour mieux accueillir le texte
                                            height: 24,
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.black,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center( // Remplacement du Column par Center pour simplifier
                                              child: Text(
                                                '$storyCount',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12, // Taille de police réduite pour éviter les débordements
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            margin: const EdgeInsets.only(top: 5, left: 5),
                                            child: CircleAvatar(
                                              radius: 30,
                                              backgroundImage: profileUrl.isNotEmpty && profileUrl.startsWith('http')
                                                ? NetworkImage(profileUrl)
                                                  :null,
                                              child: profileUrl.isEmpty || !profileUrl.startsWith('http')
                                                ? const Icon(Icons.person)
                                                  : null,
                                            ),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.only( top:120, left: 10),
                                            child: Text(
                                              username,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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