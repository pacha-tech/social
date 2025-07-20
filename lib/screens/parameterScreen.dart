import 'package:flutter/material.dart';
import '../services/authService.dart';

class ParameterScreen extends StatelessWidget {
  ParameterScreen({super.key});

  final AuthService authService = AuthService();

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la déconnexion'),
          content: const Text('Es-tu sûr de vouloir te déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Ferme la popup
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Ferme la popup
                await authService.signOut();
                // ⚡️ Redirige vers ta page de login si nécessaire :
                // Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text(
                'Se déconnecter',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Changer le thème'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Changer thème pas encore dispo')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Modifier le profil'),
            onTap: () {
              // ⚡️ Navigue vers page profil si besoin
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Se déconnecter'),
            onTap: () => _showLogoutConfirmation(context),
          ),
        ],
      ),
    );
  }
}
