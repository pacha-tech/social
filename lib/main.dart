import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // ✅ Import pour App Check

import 'screens/bottom_bar.dart';
import 'screens/authScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialise Firebase
  await Firebase.initializeApp();

  // ✅ Active Firebase App Check avec Play Integrity pour Android
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    // iosProvider: IOSProvider.deviceCheck, // 👉 Décommente si tu veux gérer iOS aussi
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mon App Social',
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(), // 🔥 Gère la navigation en fonction de l’authentification
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Pendant le chargement de Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Utilisateur connecté ? => HomePage
        if (snapshot.hasData) {
          return BottomBar();
        }

        // Sinon => AuthPage
        return const AuthPage();
      },
    );
  }
}
