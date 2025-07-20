import 'package:flutter/material.dart';
import 'storyViewer.dart';

class MyStoryCard extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function() getMyStory;
  final Future<void> Function() onAddStory;

  const MyStoryCard({
    super.key,
    required this.getMyStory,
    required this.onAddStory,
  });

  @override
  State<MyStoryCard> createState() => _MyStoryCardState();
}

class _MyStoryCardState extends State<MyStoryCard> {
  bool _isUploading = false;

  Future<void> handleAddStory() async {
    setState(() {
      _isUploading = true;
    });

    await widget.onAddStory();

    setState(() {
      _isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: widget.getMyStory(),
      builder: (context, snapshot) {
        if (_isUploading || snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 150,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final myStories = snapshot.data ?? [];
        final lastStoryUrl = myStories.isNotEmpty ? myStories.last['mediaUrl'] as String : null;

        return Container(
          width: 150,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (myStories.isEmpty) {
                  handleAddStory();
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => StoryViewer(
                          stories: myStories,
                          initialIndex: 0,
                        )
                    )
                  );
                }
              },
              child: Stack(
                children: [
                  if (lastStoryUrl != null)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          lastStoryUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                        ),
                      ),
                    ),

                  // ✅ BADGE du nombre de stories en haut à droite
                  if (myStories.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${myStories.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  if (myStories.isEmpty)
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_circle_outline, size: 48, color: Colors.green),
                          SizedBox(height: 10),
                          Text(
                            'Ajouter Story',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (myStories.isNotEmpty)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: InkWell(
                        onTap: handleAddStory,
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.add, size: 20, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
