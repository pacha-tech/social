import 'package:flutter/material.dart';

class StoryViewer extends StatefulWidget {
  final List<Map<String, dynamic>> stories;
  final int initialIndex;

  const StoryViewer({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  late int currentIndex;
  //late final PageController _controller;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    //_controller = PageController(initialPage: widget.initialIndex);
  }

  void goPrevious() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
    }
  }

  void goNext() {
    if (currentIndex < widget.stories.length - 1) {
      setState(() {
        currentIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[currentIndex];
    final mediaUrl = story['mediaUrl'] as String;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Image.network(
              mediaUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const CircularProgressIndicator();
              },
              errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.white),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          // Compteur en haut au centre
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${currentIndex + 1} / ${widget.stories.length}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Bouton gauche
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: goPrevious,
              child: const SizedBox(
                width: 80,
                child: Icon(Icons.arrow_back_ios, color: Colors.white, size: 32),
              ),
            ),
          ),
          // Bouton droit
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: goNext,
              child: const SizedBox(
                width: 80,
                child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
