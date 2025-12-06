// Importation des bibliothèques nécessaires
import 'package:firebase_auth/firebase_auth.dart'; // Pour l'authentification Firebase
import 'package:flutter/material.dart'; // Pour les widgets Flutter
import 'SignUpScreen.dart'; // Écran d'inscription
import 'User/screens/HomeScreen.dart'; // Écran principal après connexion

// Définition du widget LoginScreen (stateful)
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

// État du widget LoginScreen
class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(); // Contrôleur pour le champ email
  final _passwordController = TextEditingController(); // Contrôleur pour le champ mot de passe
  bool _isLoading = false; // Indicateur de chargement
  String _errorMessage = ''; // Message d'erreur éventuel

  // Gère la connexion de l'utilisateur
  Future<void> _handleLogin() async {
    // Vérifie si les champs sont remplis
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Veuillez remplir tous les champs');
      return;
    }

    setState(() {
      _isLoading = true; // Affiche l'indicateur de chargement
      _errorMessage = ''; // Réinitialise le message d'erreur
    });

    try {
      // Tente de connecter l'utilisateur via Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Redirige vers l'écran principal
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      // Gère les erreurs Firebase
      setState(() => _errorMessage = _getErrorMessage(e.code));
    } finally {
      setState(() => _isLoading = false); // Arrête l'indicateur de chargement
    }
  }

  // Traduit les codes d'erreur Firebase en messages lisibles
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
        return 'Email ou mot de passe incorrect';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      default:
        return 'Erreur de connexion';
    }
  }

  // Construit l'interface utilisateur
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Fond avec un dégradé subtil
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFb97d09).withOpacity(0.1),
              Color(0xFF13B502).withOpacity(0.05),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo de l'application
                Image.asset(
                  'assets/logo_bee.png',
                  height: 230,
                ),
                SizedBox(height: 10),
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
                  isPassword: true,
                ),
                SizedBox(height: 30),
                // Affiche un message d'erreur si nécessaire
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                // Bouton de connexion
                _buildActionButton(
                  text: 'Se connecter',
                  color: Color(0xFFef9c04),
                  onPressed: _handleLogin,
                ),
                SizedBox(height: 15),
                // Bouton pour créer un compte
                _buildActionButton(
                  text: 'Créer un compte',
                  color: Color(0xFF565b1d),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpScreen()),
                    );
                  },
                ),
                SizedBox(height: 20),
                // Bouton pour mot de passe oublié (non implémenté)
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Mot de passe oublié?',
                    style: TextStyle(
                      color: Color(0xFFB27C34),
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

  // Construit un champ de texte
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword, // Masque le texte pour les mots de passe
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFFD4A001)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFEDDADF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFb97d09), width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
      ),
    );
  }

  // Construit un bouton d'action
  Widget _buildActionButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          shadowColor: color.withOpacity(0.4),
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white) // Affiche un indicateur pendant le chargement
            : Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}