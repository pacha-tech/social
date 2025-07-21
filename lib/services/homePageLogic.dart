import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'cloudinaryService.dart';

class HomePageLogic {

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

      // Regrouper les stories par utilisateur
      final Map<String, List<Map<String, dynamic>>> groupedStories = {};
      for (var story in allStories) {
        final uid = story['uid'] as String;
        if (!groupedStories.containsKey(uid)) {
          groupedStories[uid] = [];
        }
        groupedStories[uid]!.add(story);
      }

      // Créer la liste finale des stories
      final List<Map<String, dynamic>> result = [];

      // Ajouter la story de l'utilisateur connecté (s'il y en a)
      if (groupedStories.containsKey(user.uid)) {
        final myStories = groupedStories[user.uid]!;
        // Trier par createdAt pour obtenir la dernière story
        myStories.sort((a, b) {
          final aTs = a['createdAt'] as Timestamp?;
          final bTs = b['createdAt'] as Timestamp?;
          return (bTs?.compareTo(aTs!) ?? 0);
        });
        result.add({
          'uid': user.uid,
          'mediaUrl': myStories.first['mediaUrl'],
          'type': myStories.first['type'],
          'docId': myStories.first['docId'],
          'createdAt': myStories.first['createdAt'],
          'expireAt': myStories.first['expireAt'],
          'storyCount': myStories.length, // Nombre total de stories
        });
      } else {
        // Ajouter une entrée vide pour l'utilisateur connecté
        result.add({
          'uid': user.uid,
          'storyCount': 0,
        });
      }

      // Ajouter les stories des autres utilisateurs
      groupedStories.forEach((uid, stories) {
        if (uid != user.uid) {
          // Trier par createdAt pour obtenir la dernière story
          stories.sort((a, b) {
            final aTs = a['createdAt'] as Timestamp?;
            final bTs = b['createdAt'] as Timestamp?;
            return (bTs?.compareTo(aTs!) ?? 0);
          });
          result.add({
            'uid': uid,
            'mediaUrl': stories.first['mediaUrl'],
            'type': stories.first['type'],
            'docId': stories.first['docId'],
            'createdAt': stories.first['createdAt'],
            'expireAt': stories.first['expireAt'],
            'storyCount': stories.length, // Nombre total de stories
          });
        }
      });

      // Trier les stories des autres utilisateurs par createdAt
      result.sort((a, b) {
        if (a['uid'] == user.uid) return -1; // L'utilisateur connecté en premier
        if (b['uid'] == user.uid) return 1;
        final aTs = a['createdAt'] as Timestamp?;
        final bTs = b['createdAt'] as Timestamp?;
        return (bTs?.compareTo(aTs!) ?? 0);
      });

      return result;
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
    /*
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final querySnapshot = await FirebaseFirestore.instance
        .collection('stories')
        .where('uid', isEqualTo: user.uid)
        .where('expireAt', isGreaterThan: Timestamp.now())
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
     */
      return getUserStories(FirebaseAuth.instance.currentUser?.uid ?? '');
  }

  Future<void> addStory(BuildContext context) async {
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
          'type': mediaType,
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

  Future<List<Map<String, dynamic>>> getUserStories(String uid) async {
    if (uid.isEmpty) return [];

    final querySnapshot = await FirebaseFirestore.instance
        .collection('stories')
        .where('uid', isEqualTo: uid)
        .where('expireAt', isGreaterThan: Timestamp.now())
        .get();

    final stories = querySnapshot.docs.map((doc) => {
      ...doc.data(),
      'docId': doc.id,
    }).toList();

    // Trier les stories par createdAt (du plus récent au plus ancien)
    stories.sort((a, b) {
      final aTs = a['createdAt'] as Timestamp?;
      final bTs = b['createdAt'] as Timestamp?;
      return (bTs?.compareTo(aTs!) ?? 0);
    });

    return stories;
  }
}