import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'User/screens/HomeScreen.dart';

/// Écran d'inscription permettant aux utilisateurs de créer un nouveau compte
/// Ce widget est de type StatefulWidget car il gère un état interne (formulaire, chargement, erreurs)
class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

/// Classe d'état pour gérer la logique et l'interface de l'écran d'inscription
class _SignUpScreenState extends State<SignUpScreen> {
  // Contrôleurs pour les champs de formulaire
  final _emailController = TextEditingController();  // Gère le champ email
  final _passwordController = TextEditingController();  // Gère le champ du mot de passe
  final _confirmPasswordController = TextEditingController();  // Gère le champ de confirmation du mot de passe

  // Variables d'état
  bool _isLoading = false;  // Indicateur de chargement pendant l'inscription
  String _errorMessage = '';  // Message d'erreur à afficher

  /// Fonction asynchrone qui gère le processus d'inscription
  Future<void> _handleSignUp() async {
    // Vérification si les mots de passe correspondent
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Les mots de passe ne correspondent pas');
      return;
    }

    // Activation du chargement et effacement des erreurs précédentes
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Tentative de création d'un nouvel utilisateur avec Firebase Authentication
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),  // Suppression des espaces inutiles
        password: _passwordController.text.trim(),
      );

      // Redirection vers l'écran d'accueil en cas de succès
      // Le remplacement empêche de revenir à l'écran d'inscription avec le bouton retour
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      // Gestion des erreurs spécifiques à Firebase Auth
      setState(() => _errorMessage = _getErrorMessage(e.code));
    } finally {
      // Désactivation de l'indicateur de chargement, que l'opération réussisse ou échoue
      setState(() => _isLoading = false);
    }
  }

  /// Fonction qui traduit les codes d'erreur Firebase en messages compréhensibles en français
  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'weak-password':
        return 'Mot de passe trop faible (min. 6 caractères)';
      case 'invalid-email':
        return 'Email invalide';
      default:
        return 'Erreur d\'inscription';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Fond avec dégradé pour améliorer l'esthétique
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFb97d09).withOpacity(0.1),  // Couleur ambrée légère en haut
              Color(0xFF13B502).withOpacity(0.05),  // Couleur verte légère en bas
            ],
          ),
        ),
        child: Center(
          // SingleChildScrollView permet de faire défiler le contenu si l'écran est trop petit
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo de l'application
                Image.asset(
                  'assets/logo_bee.png',
                  height: 200,
                ),
                SizedBox(height: 10),  // Espacement vertical

                // Titre de l'écran
                Text(
                  'Créer un compte',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4D2512),  // Couleur marron foncé
                  ),
                ),
                SizedBox(height: 28),

                // Champ pour l'email
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                ),
                SizedBox(height: 20),

                // Champ pour le mot de passe
                _buildTextField(
                  controller: _passwordController,
                  label: 'Mot de passe',
                  icon: Icons.lock,
                  isPassword: true,  // Cache les caractères saisis
                ),
                SizedBox(height: 20),

                // Champ pour confirmer le mot de passe
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirmer le mot de passe',
                  icon: Icons.lock_outline,
                  isPassword: true,  // Cache les caractères saisis
                ),
                SizedBox(height: 35),

                // Affichage conditionnel du message d'erreur
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),

                // Bouton d'inscription
                _buildActionButton(
                  text: 'S\'inscrire',
                  color: Color(0xFFef9c04),  // Couleur orange/ambre
                  onPressed: _handleSignUp,  // Fonction appelée lors du clic
                ),
                SizedBox(height: 20),

                // Lien pour naviguer vers l'écran de connexion
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);  // Retourne à l'écran précédent (login)
                  },
                  child: Text(
                    'Déjà un compte? Se connecter',
                    style: TextStyle(
                      color: Color(0xFFB27C34),  // Couleur ambrée pour le texte
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Méthode qui construit un champ de texte stylisé et réutilisable
  /// Paramètres:
  /// - controller: pour gérer la valeur du champ
  /// - label: texte affiché comme étiquette
  /// - icon: icône affichée devant le champ
  /// - isPassword: si true, masque le texte saisi (pour les mots de passe)
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,  // Masque le texte si c'est un mot de passe
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFFD4A001)),  // Icône avec couleur dorée
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),  // Bords arrondis
          borderSide: BorderSide(color: Color(0xFFEDDADF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFb97d09), width: 2),  // Bordure plus épaisse quand focus
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),  // Fond légèrement transparent
      ),
    );
  }

  /// Méthode qui construit un bouton d'action stylisé et réutilisable
  /// Paramètres:
  /// - text: texte affiché sur le bouton
  /// - color: couleur principale du bouton
  /// - onPressed: fonction appelée lorsque le bouton est cliqué
  Widget _buildActionButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,  // Bouton qui prend toute la largeur disponible
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 16),  // Espacement interne vertical
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),  // Bords arrondis
          ),
          elevation: 3,  // Ombre sous le bouton
          shadowColor: color.withOpacity(0.4),  // Couleur de l'ombre
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)  // Indicateur de chargement
            : Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,  // Texte blanc
          ),
        ),
      ),
    );
  }
}