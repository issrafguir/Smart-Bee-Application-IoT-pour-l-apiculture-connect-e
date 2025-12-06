// Importation des bibliothèques nécessaires
import 'dart:async'; // Pour gérer les tâches asynchrones (Timer, etc.)
import 'package:flutter/material.dart'; // Pour les widgets Flutter
import 'package:http/http.dart' as http; // Pour effectuer des requêtes HTTP
import 'dart:convert'; // Pour encoder/décoder JSON
import 'package:fl_chart/fl_chart.dart'; // Pour afficher des graphiques
import 'package:intl/intl.dart'; // Pour formater les dates
import 'package:webview_flutter/webview_flutter.dart'; // Pour afficher une WebView

// Définition du widget MetricDetailScreen (stateless)
class MetricDetailScreen extends StatefulWidget {
  final String metricName; // Nom de la métrique (ex. Température intérieure)
  final String fieldNumber; // Numéro du champ dans ThingSpeak
  final String unit; // Unité de mesure (ex. °C, %, etc.)
  final Color color; // Couleur associée à la métrique

  MetricDetailScreen({
    required this.metricName,
    required this.fieldNumber,
    required this.unit,
    required this.color,
  });

  @override
  _MetricDetailScreenState createState() => _MetricDetailScreenState();
}

// État du widget MetricDetailScreen
class _MetricDetailScreenState extends State<MetricDetailScreen> {
  List<Map<String, dynamic>> historicalData = []; // Stocke les données historiques
  bool _isLoading = true; // Indicateur de chargement
  String? _errorMessage; // Message d'erreur éventuel
  Timer? _timer; // Timer pour rafraîchir les données
  late WebViewController _webViewController; // Contrôleur pour la WebView
  final ScrollController _scrollController = ScrollController(); // Contrôleur pour le défilement
  String? _selectedDay; // Jour sélectionné pour filtrer les données

  // Configuration de ThingSpeak
  final String thingSpeakApiKey = 'V41CBX0ZPHZ5YWKS'; // Clé API ThingSpeak
  final String channelId = '2947015'; // ID du canal ThingSpeak
  final String thingSpeakHistoryUrl =
      'https://api.thingspeak.com/channels/2947015/feeds.json?api_key=V41CBX0ZPHZ5YWKS&results=50'; // URL pour récupérer les 50 dernières données

  @override
  void initState() {
    super.initState();
    _fetchHistoricalData(); // Récupère les données historiques au démarrage
    _startDataRefresh(); // Démarre le rafraîchissement périodique
    // Initialisation du contrôleur WebView pour afficher le graphique ThingSpeak
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Active JavaScript
      ..setUserAgent('Mozilla/5.0 ...') // Définit un User-Agent pour compatibilité
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) => setState(() => _isLoading = true), // Début du chargement
          onPageFinished: (String url) {
            setState(() => _isLoading = false); // Fin du chargement
            // Manipulation JavaScript pour ajuster l'échelle du graphique
            _webViewController.runJavaScript('''
              const chartContainer = document.querySelector(".chart-container");
              if (chartContainer) {
                chartContainer.style.transform = "scale(5.0)"; // Zoom sur le graphique
                chartContainer.style.transformOrigin = "center top";
                document.body.style.overflow = "hidden";
              }
            ''');
          },
          onWebResourceError: (error) {
            setState(() {
              _errorMessage = 'Erreur de chargement du graphique ThingSpeak: ${error.description}';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(
          'https://thingspeak.com/channels/$channelId/charts/${widget.fieldNumber}?api_key=$thingSpeakApiKey&width=900&height=700')); // Charge le graphique ThingSpeak
  }

  @override
  void dispose() {
    _timer?.cancel(); // Arrête le timer
    _scrollController.dispose(); // Libère le contrôleur de défilement
    super.dispose();
  }

  // Récupère les données historiques depuis ThingSpeak
  Future<void> _fetchHistoricalData() async {
    try {
      final response = await http.get(Uri.parse(thingSpeakHistoryUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          historicalData = List<Map<String, dynamic>>.from(data['feeds'])
              .where((feed) => feed['created_at'] != null) // Filtre les données invalides
              .toList()
              .reversed // Inverse l'ordre (plus récent en premier)
              .toList();
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

  // Configure le rafraîchissement automatique des données toutes les 30 secondes
  void _startDataRefresh() {
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      _fetchHistoricalData();
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

  // Retourne l'icône appropriée pour la métrique
  IconData _getMetricIcon() {
    switch (widget.metricName.toLowerCase()) {
      case 'température intérieure':
        return Icons.thermostat;
      case 'humidité intérieure':
        return Icons.water_drop;
      case 'poids':
        return Icons.scale;
      case 'mouvement':
        return Icons.waves;
      case 'co2':
        return Icons.co2;
      case 'activité':
        return Icons.volume_up;
      default:
        return Icons.info;
    }
  }

  // Défile vers la section historique
  void _scrollToHistory() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  // Regroupe les données par jour
  Map<String, List<Map<String, dynamic>>> _groupDataByDay() {
    Map<String, List<Map<String, dynamic>>> groupedData = {};
    for (var data in historicalData) {
      if (data['created_at'] == null) continue;
      try {
        final date = DateTime.parse(data['created_at']);
        final dayKey = DateFormat('yyyy-MM-dd').format(date);
        if (!groupedData.containsKey(dayKey)) {
          groupedData[dayKey] = [];
        }
        groupedData[dayKey]!.add(data);
      } catch (e) {
        continue;
      }
    }
    return groupedData;
  }

  // Liste des jours disponibles pour le filtre
  List<String> _getAvailableDays() {
    final groupedData = _groupDataByDay();
    final days = groupedData.keys.toList();
    days.sort((a, b) => b.compareTo(a)); // Trie par ordre décroissant
    return ['Tous les jours', ...days];
  }

  // Filtre les données selon le jour sélectionné
  List<Map<String, dynamic>> _getFilteredData() {
    if (_selectedDay == null || _selectedDay == 'Tous les jours') {
      return historicalData;
    }
    final groupedData = _groupDataByDay();
    return groupedData[_selectedDay] ?? [];
  }

  // Construction de l'interface utilisateur
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.metricName),
        backgroundColor: widget.color,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: _scrollToHistory,
            tooltip: 'Voir l\'historique',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F5F0), Color(0xFFEDE4D5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: widget.color))
            : _errorMessage != null
            ? Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.red)))
            : RefreshIndicator(
          onRefresh: _fetchHistoricalData,
          color: widget.color,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGraph(), // Affiche le graphique local
                SizedBox(height: 20),
                _buildThingSpeakVisualization(), // Affiche le graphique ThingSpeak
                SizedBox(height: 20),
                Divider(color: Color(0xFFB27C34), thickness: 1),
                SizedBox(height: 10),
                _buildHistoricalData(), // Affiche l'historique des données
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Construit le graphique local avec fl_chart
  Widget _buildGraph() {
    final filteredData = _getFilteredData();
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.metricName} - Graphique',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4D2512)),
            ),
            SizedBox(height: 20),
            Container(
              height: 250,
              child: filteredData.isEmpty
                  ? Center(child: Text('Aucune donnée pour afficher le graphique', style: TextStyle(color: Color(0xFF4D2512))))
                  : LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= filteredData.length) return Text('');
                          final date = DateTime.parse(filteredData[index]['created_at']);
                          return Text(DateFormat('HH:mm').format(date));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: filteredData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final value = double.tryParse(entry.value['field${widget.fieldNumber}']?.toString() ?? '0') ?? 0;
                        return FlSpot(index.toDouble(), value);
                      }).toList(),
                      isCurved: true,
                      color: widget.color,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construit la visualisation ThingSpeak via WebView
  Widget _buildThingSpeakVisualization() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.metricName} - Visualisation ThingSpeak',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4D2512)),
            ),
            SizedBox(height: 20),
            Container(
              height: 150,
              child: WebViewWidget(controller: _webViewController),
            ),
          ],
        ),
      ),
    );
  }

  // Construit la liste des données historiques
  Widget _buildHistoricalData() {
    final availableDays = _getAvailableDays();
    final filteredData = _getFilteredData();

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.metricName} - Historique',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4D2512)),
                ),
                Row(children: [
                  SizedBox(width: 90),
                  DropdownButton<String>(
                    value: _selectedDay ?? 'Tous les jours',
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedDay = newValue == 'Tous les jours' ? null : newValue;
                      });
                    },
                    items: availableDays.map<DropdownMenuItem<String>>((String day) {
                      return DropdownMenuItem<String>(
                        value: day,
                        child: Text(
                          day == 'Tous les jours'
                              ? 'Tous les jours  '
                              : DateFormat('dd/MM/yyyy').format(DateTime.parse(day)),
                          style: TextStyle(color: Color(0xFF4D2512)),
                        ),
                      );
                    }).toList(),
                    underline: Container(),
                    icon: Icon(Icons.calendar_today, color: widget.color),
                  ),
                ]),
              ],
            ),
            SizedBox(height: 20),
            filteredData.isEmpty
                ? Center(
              child: Text(
                'Aucune donnée pour ${_selectedDay == null ? "cette période" : DateFormat('dd/MM/yyyy').format(DateTime.parse(_selectedDay!))}',
                style: TextStyle(color: Color(0xFF4D2512)),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: filteredData.length,
              itemBuilder: (context, index) {
                final data = filteredData[index];
                final date = DateTime.parse(data['created_at']);
                final value = _formatValue(data['field${widget.fieldNumber}']);
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: AnimatedOpacity(
                    opacity: _isLoading ? 0.0 : 1.0,
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white, Color(0xFFF8F5F0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.color.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_getMetricIcon(), color: widget.color, size: 24),
                          ),
                          title: Text(
                            '$value ${widget.unit}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4D2512)),
                          ),
                          subtitle: Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(date),
                            style: TextStyle(fontSize: 14, color: Color(0xFFB27C34)),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}