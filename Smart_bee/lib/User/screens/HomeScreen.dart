// Importation des bibliothèques nécessaires
import 'dart:async'; // Pour gérer les tâches asynchrones (Timer)
import 'package:flutter/material.dart'; // Pour les widgets Flutter
import 'package:firebase_auth/firebase_auth.dart'; // Pour l'authentification Firebase
import 'package:http/http.dart' as http; // Pour effectuer des requêtes HTTP
import 'dart:convert'; // Pour encoder/décoder JSON
import 'package:fl_chart/fl_chart.dart'; // Pour afficher des graphiques (non utilisé ici)
import 'package:intl/intl.dart'; // Pour formater les dates
import '../../LoginScreen.dart'; // Écran de connexion
import 'AlertsScreen.dart'; // Écran des alertes
import 'MetricsDetailsScreen.dart'; // Écran des détails des métriques

// Définition du widget HomeScreen (stateful)
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

// État du widget HomeScreen
class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser; // Utilisateur connecté via Firebase
  Map<String, dynamic>? sensorData; // Données des capteurs (ThingSpeak)
  Map<String, dynamic>? weatherData; // Données météo (non utilisé ici)
  bool _isLoading = true; // Indicateur de chargement
  String? _errorMessage; // Message d'erreur éventuel
  Timer? _timer; // Timer pour rafraîchir les données
  double _opacity = 0.0; // Opacité pour l'animation d'apparition

  // Configuration ThingSpeak
  final String thingSpeakUrl =
      'https://api.thingspeak.com/channels/2947015/feeds/last.json?api_key=V41CBX0ZPHZ5YWKS'; // URL pour les dernières données

  // Configuration OpenWeatherMap (non utilisé ici)
  final String weatherApiKey = 'YOUR_OPENWEATHERMAP_API_KEY';

  // Seuils pour déclencher des alertes
  final Map<String, double> thresholds = {
    'Temp. Intérieur': 30.0,
    'Hum. Intérieur': 80.0,
    'CO2': 1000.0,
    'Activité': 70.0,
    'Poids': 100.0,
    'Mouvement': 50.0,
    'Temp. Extérieur': 35.0,
    'Hum. Extérieur': 85.0,
  };

  // Gestion du délai entre alertes
  final Map<String, DateTime> _lastAlertTimes = {}; // Dernière alerte pour chaque métrique
  final Duration _alertCooldown = Duration(minutes: 5); // Délai de 5 minutes entre alertes

  // Suivi des alertes actives
  int _alertCount = 0; // Nombre d'alertes actives
  final List<String> _activeAlerts = []; // Liste des alertes actives

  @override
  void initState() {
    super.initState();
    _fetchSensorData(); // Récupère les données des capteurs au démarrage
    _startDataRefresh(); // Démarre le rafraîchissement périodique
    // Animation d'apparition après 200ms
    Future.delayed(Duration(milliseconds: 200), () {
      setState(() => _opacity = 1.0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Arrête le timer
    super.dispose();
  }

  // Récupère les dernières données des capteurs depuis ThingSpeak
  Future<void> _fetchSensorData() async {
    try {
      final response = await http.get(Uri.parse(thingSpeakUrl));
      if (response.statusCode == 200) {
        setState(() {
          sensorData = json.decode(response.body);
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur de connexion à ThingSpeak (Code: ${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur de connexion: ${e.toString()}';
      });
    }
  }

  // Configure le rafraîchissement automatique toutes les 30 secondes
  void _startDataRefresh() {
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      _fetchSensorData();
    });
  }

  // Formate une valeur numérique pour l'affichage
  String _formatValue(dynamic value) {
    if (value == null) return '--';
    try {
      double numValue = double.parse(value.toString());
      return numValue.toStringAsFixed(1).replaceAll('.', ','); // Format avec 1 décimale
    } catch (e) {
      return '--';
    }
  }

  // Vérifie si une métrique dépasse son seuil et déclenche une alerte si nécessaire
  void _checkThresholdAndAlert(String label, String value, BuildContext context) {
    try {
      // Nettoie et convertit la valeur en nombre
      double numericValue = double.parse(value.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.'));
      double? threshold = thresholds[label];

      if (threshold != null && numericValue > threshold) {
        DateTime now = DateTime.now();
        DateTime? lastAlert = _lastAlertTimes[label];

        // Vérifie le délai de refroidissement
        if (lastAlert == null || now.difference(lastAlert) > _alertCooldown) {
          _lastAlertTimes[label] = now;
          String alertKey = '$label-$value';
          if (!_activeAlerts.contains(alertKey)) {
            _activeAlerts.add(alertKey);
            setState(() {
              _alertCount++; // Incrémente le compteur d'alertes
            });
            // Affiche une notification via SnackBar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '$label a dépassé le seuil ! Valeur: $value',
                  style: TextStyle(fontSize: 17),
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      // Gère les erreurs de conversion silencieusement
    }
  }

  // Efface toutes les alertes
  void _clearAlerts() {
    setState(() {
      _alertCount = 0;
      _activeAlerts.clear();
    });
  }

  // Construit l'interface utilisateur
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDateTime = DateFormat('dd/MM/yyyy HH:mm').format(now);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        // Fond avec dégradé
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F5F0), Color(0xFFEDE4D5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(), // En-tête personnalisé
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  'Dernière mise à jour: $formattedDateTime',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: Color(0xFFD4A001)))
                    : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.red)))
                    : RefreshIndicator(
                  // Permet de rafraîchir manuellement
                  onRefresh: _fetchSensorData,
                  color: Color(0xFFF2D80C),
                  backgroundColor: Color(0xFFEDDADF),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    physics: AlwaysScrollableScrollPhysics(),
                    child: AnimatedOpacity(
                      opacity: _opacity,
                      duration: Duration(milliseconds: 500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
                          _buildMeasurementsCard(), // Carte des mesures
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: _buildDrawer(), // Menu latéral
    );
  }

  // Construit l'en-tête
  Widget _buildHeader() {
    final now = DateTime.now();
    final formattedDateTime = DateFormat('dd/MM/yyyy HH:mm').format(now);
    final userName = user?.displayName ?? user?.email ?? 'Utilisateur';

    return Builder(
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFef9c04), Color(0xFFD4A001)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Bouton pour ouvrir le menu
                      IconButton(
                        icon: Icon(Icons.menu, color: Colors.white, size: 30),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Bee Care Full',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black26, offset: Offset(2, 2))],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Bouton des notifications
                      Stack(
                        children: [
                          IconButton(
                            icon: Icon(Icons.notifications, color: Colors.white, size: 30),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AlertsScreen(
                                    alerts: _activeAlerts,
                                    onClear: _clearAlerts,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Badge pour le nombre d'alertes
                          if (_alertCount > 0)
                            Positioned(
                              right: 5,
                              top: 5,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Center(
                                  child: Text(
                                    '$_alertCount',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Bouton de rafraîchissement manuel
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.white, size: 30),
                        onPressed: _fetchSensorData,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              Center(
                child: Text(
                  '  $formattedDateTime',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Construit le menu latéral
  Widget _buildDrawer() {
    final userEmail = user?.email ?? 'email@exemple.com';
    return Drawer(
      backgroundColor: Color(0xFFF8F5F0),
      width: MediaQuery.of(context).size.width * 0.75,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // En-tête du menu
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFef9c04), Color(0xFFD4A001)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo_bee.png',
                    width: 150,
                    height: 150,
                  ),
                  SizedBox(height: 10),
                  Text(
                    userEmail,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Liste des options du menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(Icons.home, 'Accueil', () => Navigator.pop(context)),
                _buildDrawerItem(Icons.scale, 'Poids', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MetricDetailScreen(
                        metricName: 'Poids',
                        fieldNumber: '6',
                        unit: 'kg',
                        color: Color(0xFFef9c04),
                      ),
                    ),
                  );
                }),
                _buildDrawerItem(Icons.thermostat, 'Température Intérieure', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MetricDetailScreen(
                        metricName: 'Température Intérieure',
                        fieldNumber: '1',
                        unit: '°C',
                        color: Color(0xFFe7cf9e),
                      ),
                    ),
                  );
                }),
                _buildDrawerItem(Icons.water_drop, 'Humidité Intérieure', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MetricDetailScreen(
                        metricName: 'Humidité Intérieure',
                        fieldNumber: '2',
                        unit: '%',
                        color: Color(0xFF13B502),
                      ),
                    ),
                  );
                }),
                _buildDrawerItem(Icons.waves, 'Mouvement', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MetricDetailScreen(
                        metricName: 'Mouvement',
                        fieldNumber: '4',
                        unit: 'dB',
                        color: Color(0xFFda7d04),
                      ),
                    ),
                  );
                }),
                _buildDrawerItem(Icons.co2, 'CO2', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MetricDetailScreen(
                        metricName: 'CO2',
                        fieldNumber: '3',
                        unit: 'kg',
                        color: Color(0xFFcfa85e),
                      ),
                    ),
                  );
                }),
                _buildDrawerItem(Icons.volume_up, 'Activité', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MetricDetailScreen(
                        metricName: 'Activité',
                        fieldNumber: '5',
                        unit: 'dB',
                        color: Color(0xFF13B502),
                      ),
                    ),
                  );
                }),
                Divider(color: Color(0xFFB27C34), height: 20),
                _buildDrawerItem(Icons.logout, 'Déconnexion', _signOut),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Construit un élément du menu latéral
  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF4D2512), size: 30),
      title: Text(
        title,
        style: TextStyle(
          color: Color(0xFF4D2512),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
      hoverColor: Color(0xFFF2D80C).withOpacity(0.1),
    );
  }

  // Construit la carte des mesures
  Widget _buildMeasurementsCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF8F5F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre et indicateur d'état
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'État de la Ruche',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4D2512)),
                ),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(0xFF13B502),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Saine',
                      style: TextStyle(color: Color(0xFF13B502), fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            // Mesures intérieures
            Text(
              'Intérieur',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF4D2512)),
            ),
            SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildMetric('Temp. Intérieur', Icons.thermostat, _formatValue(sensorData?['field1']) + '°C', Color(0xFFFDC103)),
                _buildMetric('Hum. Intérieur', Icons.water_drop, _formatValue(sensorData?['field2']) + '%', Color(0xFF13B502)),
                _buildMetric('CO2', Icons.co2, _formatValue(sensorData?['field3']) + 'kg', Color(0xFFB27C34)),
                _buildMetric('Activité', Icons.volume_up, _formatValue(sensorData?['field5']) + 'dB', Color(0xFF4D2512)),
                _buildMetric('Poids', Icons.scale, _formatValue(sensorData?['field6']) + 'kg', Color(0xFF4D2512)),
                _buildMetric('Mouvement', Icons.waves, _formatValue(sensorData?['field4']) + 'dB', Color(0xFF4D2512)),
              ],
            ),
            SizedBox(height: 20),
            // Mesures extérieures
            Text(
              'Extérieur',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF4D2512)),
            ),
            SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildMetric('Temp. Extérieur', Icons.thermostat, _formatValue(sensorData?['field7']) + '°C', Color(0xFF13B502)),
                _buildMetric('Hum. Extérieur', Icons.water_drop, _formatValue(sensorData?['field8']) + '%', Color(0xFF13B502)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Construit un widget pour afficher une métrique
  Widget _buildMetric(String label, IconData icon, String value, Color color) {
    // Vérifie les seuils après le rendu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkThresholdAndAlert(label, value, context);
    });

    return AnimatedScale(
      scale: _isLoading ? 0.9 : 1.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            // Icône de la métrique
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 12),
            // Valeur et label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4D2512)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: TextStyle(fontSize: 14, color: Color(0xFFB27C34), fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Déconnexion de l'utilisateur
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }
}