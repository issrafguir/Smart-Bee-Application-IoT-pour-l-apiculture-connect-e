// Importation de la bibliothèque Flutter pour les widgets
import 'package:flutter/material.dart';

// Définition du widget AlertsScreen (stateless)
class AlertsScreen extends StatelessWidget {
  final List<String> alerts; // Liste des alertes à afficher
  final VoidCallback onClear; // Fonction de rappel pour effacer les alertes
  const AlertsScreen({Key? key, required this.alerts, required this.onClear}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Fond transparent pour le Scaffold
      body: Container(
        // Décoration avec un dégradé de fond
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F5F0), Color(0xFFEDE4D5)], // Couleurs du dégradé
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          // Assure que le contenu est dans une zone sécurisée (évite les encoches, barres de navigation, etc.)
          child: Column(
            children: [
              _buildHeader(context), // Affiche l'en-tête personnalisé
              Expanded(
                // Contenu principal qui prend tout l'espace restant
                child: alerts.isEmpty
                    ? Center(
                  // Si aucune alerte, affiche un message centré
                  child: Text(
                    'Aucune alerte active',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF4D2512),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                    : ListView.builder(
                  // Si des alertes existent, affiche une liste défilante
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    // Sépare l'alerte en label et valeur (format attendu : "label-valeur")
                    final parts = alert.split('-');
                    final label = parts[0];
                    final value = parts.length > 1 ? parts[1] : 'Inconnu';
                    return Card(
                      // Carte pour chaque alerte
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          Icons.warning,
                          color: Colors.red,
                          size: 30,
                        ),
                        title: Text(
                          label,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4D2512),
                          ),
                        ),
                        subtitle: Text(
                          'Valeur: $value',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFB27C34),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Bouton pour effacer les alertes, affiché uniquement si des alertes existent
              if (alerts.isNotEmpty)
                Padding(
                  padding: EdgeInsets.all(20),
                  child: ElevatedButton(
                    onPressed: () {
                      onClear(); // Appelle la fonction de rappel pour effacer les alertes
                      Navigator.pop(context); // Ferme l'écran
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFD4A001),
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Effacer toutes les alertes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Construit l'en-tête de l'écran
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      // Décoration avec un dégradé pour l'en-tête
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFef9c04), Color(0xFFD4A001)], // Couleurs du dégradé
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Bouton de retour
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
              SizedBox(width: 10),
              // Titre de l'en-tête
              Text(
                'Alertes Actives',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black26,
                      offset: Offset(2, 2),
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
