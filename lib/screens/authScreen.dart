import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/authService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cloudinaryService.dart';
import 'home/homePage.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  final _dobController = TextEditingController();

  bool isLogin = false;
  String errorMessage = '';

  File? _profileImage;

  Future<void> pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> submit() async {
    try {
      final auth = AuthService();

      if (isLogin) {
        await auth.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        final user = await auth.signUpWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
          _cityController.text.trim(),
          _bioController.text.trim(),
          _dobController.text.trim(),
        );

        if(user != null){
          if(_profileImage != null){
            final downloadUrl = await uploadProfilePicture(_profileImage! , user.uid);
            if(downloadUrl != null){
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .update({
                'profilePictureUrl':downloadUrl,
              });
            }else{
              throw Exception('❌ Erreur Cloudinary');
            }
          }else{
            throw Exception('❌ Utilisateur non creer');
          }
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  InputDecoration customInputDecoration(
      String label, {
        bool optional = false,
        String? hintText,
      }) {
    return InputDecoration(
      labelText: optional ? '$label (facultatif)' : label,
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.green, width: 2),
      ),
    );
  }

  Widget buildStyledTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    bool optional = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: customInputDecoration(
          label,
          optional: optional,
          hintText: hintText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          'Authentification',
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (!isLogin) ...[
                GestureDetector(
                  onTap: pickImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage:
                    _profileImage != null ? FileImage(_profileImage!) : null,
                    child: _profileImage == null
                        ? const Icon(Icons.add_a_photo, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                buildStyledTextField(
                  controller: _nameController,
                  label: 'Nom',
                ),
                buildStyledTextField(
                  controller: _cityController,
                  label: 'Ville',
                ),
                buildStyledTextField(
                  controller: _bioController,
                  label: 'Bio',
                  optional: true,
                  maxLines: 3,
                ),
                buildStyledTextField(
                  controller: _dobController,
                  label: 'Date de Naissance',
                  hintText: 'yyyy-mm-dd',
                  keyboardType: TextInputType.multiline,
                ),
              ],
              buildStyledTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              buildStyledTextField(
                controller: _passwordController,
                label: 'Mot de passe',
                obscureText: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: submit,
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(isLogin ? 'Connexion' : 'Inscription'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                  });
                },
                child: Text(
                  isLogin ? 'Créer un nouveau compte' : 'J\'ai déjà un compte',
                ),
              ),
              if (errorMessage.isNotEmpty)
                Text(errorMessage, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}
