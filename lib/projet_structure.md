lib/
├── main.dart                     # Point d'entrée de l'application
├── screens/                     # Écrans principaux (UI)
│   ├── auth/                    # Écrans liés à l'authentification
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── forgot_password_screen.dart
│   ├── home/                    # Écran principal (HomePage)
│   │   ├── home_page.dart
│   │   ├── home_page_logic.dart
│   ├── profile/                 # Écran de profil utilisateur
│   │   ├── profile_screen.dart
│   │   ├── profile_logic.dart
│   ├── search/                  # Écran de recherche d'amis
│   │   ├── search_friends_screen.dart
│   │   ├── search_friends_logic.dart
│   ├── settings/                # Écran des paramètres
│   │   ├── parameter_screen.dart
│   │   ├── parameter_logic.dart
├── widgets/                     # Widgets réutilisables
│   ├── my_story_card.dart       # Widget pour afficher une story
│   ├── post_card.dart           # Widget pour afficher un post
│   ├── user_avatar.dart         # Widget pour l'avatar utilisateur
│   ├── custom_button.dart       # Bouton personnalisé
├── services/                    # Logique métier et intégrations externes
│   ├── auth_service.dart        # Gestion de l'authentification Firebase
│   ├── firestore_service.dart   # Gestion des appels Firestore
│   ├── cloudinary_service.dart  # Gestion des uploads vers Cloudinary
│   ├── storage_service.dart     # Gestion du stockage local ou Firebase Storage
├── models/                      # Modèles de données
│   ├── user_model.dart          # Modèle pour les données utilisateur
│   ├── story_model.dart         # Modèle pour les stories
│   ├── post_model.dart          # Modèle pour les posts
├── constants/                   # Constantes globales
│   ├── app_colors.dart          # Couleurs de l'application
│   ├── app_strings.dart         # Chaînes de texte statiques
│   ├── app_sizes.dart           # Tailles et dimensions
├── utils/                       # Utilitaires et configurations
│   ├── firebase_config.dart     # Configuration Firebase
│   ├── error_handler.dart       # Gestion des erreurs
│   ├── logger.dart              # Outil de logging
│   ├── validators.dart          # Validation des formulaires
├── routes/                      # Gestion des routes
│   ├── app_routes.dart          # Définition des routes nommées
├── theme/                       # Thème global de l'application
│   ├── app_theme.dart           # Configuration du thème (couleurs, typographie)
├── providers/                   # Fournisseurs pour la gestion d'état
│   ├── auth_provider.dart       # Fournisseur pour l'état d'authentification
│   ├── story_provider.dart      # Fournisseur pour les stories
│   ├── post_provider.dart       # Fournisseur pour les posts
├── assets/                      # Ressources statiques (images, polices)
│   ├── images/                  # Images locales
│   ├── fonts/                   # Polices personnalisées