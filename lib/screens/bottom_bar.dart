import 'package:flutter/material.dart';
import 'home/homePage.dart';
import 'friendsScreen.dart';
//import 'messagesScreen.dart';
//import 'notificationsScreen.dart';

class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  State<BottomBar> createState() => _MainScreenState();
}

class _MainScreenState extends State<BottomBar> {
  int _currentIndex = 0; // Index actif

  final List<Widget> _screens = [
    HomePage(),
    FriendsScreen(),
    //MessagesScreen(),
    //NotificationsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex, // Garde l'état de chaque écran
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Change d'onglet
          });
        },
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined , size: 30),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline , size: 30),
            label: 'Amis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined , size: 30),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined , size: 30),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }
}
