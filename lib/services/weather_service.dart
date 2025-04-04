import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class WeatherService {
  final String _apiKey = 'YOUR_WEATHER_API_KEY'; // Remplacez par votre clé API
  final String _baseUrl = 'https://api.weatherapi.com/v1';

  // Obtenir la météo actuelle
  Future<Map<String, dynamic>> getCurrentWeather() async {
    try {
      // Obtenir la position actuelle
      Position position = await _determinePosition();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/current.json?key=$_apiKey&q=${position.latitude},${position.longitude}'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Extraire les données pertinentes
        return {
          'temperature': data['current']['temp_c'],
          'windSpeed': data['current']['wind_kph'],
          'windDirection': data['current']['wind_degree'],
          'condition': _mapCondition(data['current']['condition']['text']),
        };
      } else {
        throw Exception('Erreur lors de la récupération des données météo');
      }
    } catch (e) {
      // En cas d'erreur, retourner des données fictives pour le développement
      return _getMockWeatherData();
    }
  }

  // Obtenir les spots recommandés
  Future<List<Map<String, dynamic>>> getRecommendedSpots() async {
    // Dans une application réelle, ces données viendraient d'une API ou d'une base de données
    // Pour l'exemple, nous utilisons des données fictives
    await Future.delayed(Duration(seconds: 1)); // Simuler un délai réseau
    
    return [
      {
        'id': '1',
        'name': 'Plage de La Torche',
        'location': 'Finistère, France',
        'imageUrl': 'https://images.unsplash.com/photo-1599571234909-29ed5d1321d6',
        'rating': 4.8,
        'windSpeed': 25,
        'waveHeight': 1.5,
        'crowdLevel': 'Modéré',
        'description': 'La Torche est l\'un des spots de windsurf les plus populaires de France, offrant des conditions parfaites pour tous les niveaux.',
      },
      {
        'id': '2',
        'name': 'Leucate',
        'location': 'Aude, France',
        'imageUrl': 'https://images.unsplash.com/photo-1565535941810-e9892acd7704',
        'rating': 4.5,
        'windSpeed': 30,
        'waveHeight': 1.0,
        'crowdLevel': 'Élevé',
        'description': 'Leucate est connu pour ses vents forts et constants, idéal pour les windsurfeurs expérimentés.',
      },
      {
        'id': '3',
        'name': 'Almanarre',
        'location': 'Hyères, France',
        'imageUrl': 'https://images.unsplash.com/photo-1576697910332-c6202e3e7a30',
        'rating': 4.2,
        'windSpeed': 20,
        'waveHeight': 0.8,
        'crowdLevel': 'Faible',
        'description': 'L\'Almanarre est un spot parfait pour les débutants et intermédiaires, avec des eaux peu profondes et des vents modérés.',
      },
    ];
  }

  // Déterminer la position actuelle
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Les services de localisation sont désactivés.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Les permissions de localisation sont refusées');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Les permissions de localisation sont définitivement refusées');
    }

    return await Geolocator.getCurrentPosition();
  }

  // Mapper la condition météo
  String _mapCondition(String apiCondition) {
    final condition = apiCondition.toLowerCase();
    
    if (condition.contains('sun') || condition.contains('clear')) return 'clear';
    if (condition.contains('cloud')) return 'cloudy';
    if (condition.contains('rain') || condition.contains('drizzle')) return 'rainy';
    if (condition.contains('thunder') || condition.contains('storm')) return 'stormy';
    
    return 'unknown';
  }

  // Données météo fictives pour le développement
  Map<String, dynamic> _getMockWeatherData() {
    return {
      'temperature': 22,
      'windSpeed': 25,
      'windDirection': 270,
      'condition': 'clear',
    };
  }
}