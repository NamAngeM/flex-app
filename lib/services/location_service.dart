// lib/services/location_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/location_model.dart';
import '../services/app_config.dart';
import '../services/dev_config.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'locations';
  final bool _devMode = AppConfig().isDevMode();
  
  // Récupérer toutes les localisations
  Future<List<LocationModel>> getAllLocations() async {
    if (_devMode) {
      // Retourner des données fictives
      return _getMockLocations();
    }
    
    final snapshot = await _firestore.collection(_collection).get();
    return snapshot.docs.map((doc) => LocationModel.fromFirestore(doc)).toList();
  }
  
  // Récupérer les localisations d'un prestataire
  Future<List<LocationModel>> getProviderLocations(String providerId) async {
    if (_devMode) {
      // Retourner des données fictives filtrées
      return _getMockLocations().where((location) => location.providerId == providerId).toList();
    }
    
    final snapshot = await _firestore
        .collection(_collection)
        .where('providerId', isEqualTo: providerId)
        .get();
    
    return snapshot.docs.map((doc) => LocationModel.fromFirestore(doc)).toList();
  }
  
  // Récupérer la localisation actuelle de l'utilisateur
  Future<Position> getCurrentLocation() async {
    // Sur le web, la géolocalisation fonctionne différemment
    if (kIsWeb) {
      try {
        return await _getWebLocation();
      } catch (e) {
        print('Erreur de localisation web: $e');
        // Retourner une position par défaut pour Paris
        return Position(
          longitude: 2.3522, 
          latitude: 48.8566,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
    }
    
    bool serviceEnabled;
    LocationPermission permission;
    
    // Vérifier si les services de localisation sont activés
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Les services de localisation sont désactivés.');
    }
    
    // Vérifier les permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Les permissions de localisation sont refusées.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Les permissions de localisation sont définitivement refusées.');
    }
    
    // Récupérer la position actuelle
    return await Geolocator.getCurrentPosition();
  }
  
  // Méthode spécifique pour la géolocalisation sur le web
  Future<Position> _getWebLocation() async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return position;
  }
  
  // Données fictives pour le mode développement
  List<LocationModel> _getMockLocations() {
    return [
      LocationModel(
        id: '1',
        name: 'Salon de Beauté Paris',
        latitude: 48.8566,
        longitude: 2.3522,
        address: '15 Rue de Rivoli, 75001 Paris',
        description: 'Salon de beauté haut de gamme au cœur de Paris',
        photoUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035',
        providerId: 'provider-test-id',
      ),
      LocationModel(
        id: '2',
        name: 'Spa Relaxant Lyon',
        latitude: 45.7640,
        longitude: 4.8357,
        address: '25 Rue de la République, 69002 Lyon',
        description: 'Spa et centre de massage professionnel',
        photoUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d',
        providerId: 'provider-test-id',
      ),
      LocationModel(
        id: '3',
        name: 'Centre Médical Marseille',
        latitude: 43.2965,
        longitude: 5.3698,
        address: '10 La Canebière, 13001 Marseille',
        description: 'Centre médical avec spécialistes',
        photoUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d',
        providerId: 'provider-test-id-2',
      ),
    ];
  }
}