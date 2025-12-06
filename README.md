# Smart Bee — Système IoT pour l’apiculture connectée

## 🎯 Objectif du Projet
Développer un système IoT complet pour la surveillance des ruches afin d’assurer la santé des abeilles et optimiser l’efficacité de l’apiculture.  

Les objectifs principaux :  
- Collecte de données en temps réel sur les ruches (température, humidité, CO₂, poids, activité)  
- Transmission et stockage sécurisé des données via IoT (MQTT, InfluxDB)  
- Visualisation interactive et analyse des données avec Grafana  
- Consultation mobile des mesures et alertes via une application Flutter  

## 🛠 Fonctionnalités
- **Surveillance intelligente des ruches** : mesure de température, humidité, CO₂, poids et activité  
- **Communication IoT** : transmission des données en temps réel via MQTT, stockage dans InfluxDB  
- **Visualisation temps réel** : tableaux et graphiques interactifs sur Grafana  
- **Application mobile Flutter** : consultation des mesures, historique et alertes en temps réel  
- **Gestion multi-ruche** : possibilité de suivre plusieurs ruches simultanément  
- **Alertes intelligentes** : notifications sur anomalies détectées dans les ruches  

## 📂 Contenu du Repository

| Fichier / Dossier | Description |
|------------------|-------------|
| `android/` | Code Flutter pour la version Android de l’application |
| `ios/` | Code Flutter pour la version iOS de l’application |
| `lib/` | Code source principal Flutter (UI, logique, services IoT) |
| `web/` | Version web de l’application Flutter |
| `windows/` | Code pour exécuter l’application Flutter sur Windows |
| `linux/` | Code pour exécuter l’application Flutter sur Linux |
| `pubspec.yaml` | Fichier de configuration Flutter (dépendances, assets) |

## 💻 Technologies et Librairies
**Langage :** Dart / Flutter  

**Technologies IoT :**  
- ThingSpeak  
- Node-RED  
- MQTT  
- InfluxDB  
- Grafana  

## ⚙️ Installation & Utilisation

# 1. Cloner le projet
git clone git@github.com:issrafguir/Smart-Bee-Application-IoT-pour-l-apiculture-connect-e.git

# 2. Se déplacer dans le dossier du projet
cd Smart_bee

# 3. Installer les dépendances Flutter
flutter pub get

# 4. Lancer l’application sur un émulateur ou un appareil physique
flutter run



## 🎬 Démo

Découvrez Smart Bee en action avec l’application mobile, le dashboard Grafana et le backend IoT.  

### Application mobile Flutter
- Consultation des mesures en temps réel : température, humidité, CO₂, poids, activité  
- Gestion multi-ruche  
- Alertes intelligentes sur anomalies  

### Dashboard Grafana
- Visualisation interactive des données collectées  
- Graphiques pour chaque paramètre des ruches  

### Vidéo Démo
Vous pouvez regarder la vidéo de démonstration ici :  
[Regarder la démo sur Google Drive](https://drive.google.com/file/d/1O7bMkj9U06TY-LJi3MK9QyKJPTnHvwUq/view?resourcekey)



