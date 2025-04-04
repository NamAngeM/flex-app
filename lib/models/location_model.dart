// lib/models/location_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final String? description;
  final String? photoUrl;
  final String? providerId;

  LocationModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.description,
    this.photoUrl,
    this.providerId,
  });

  factory LocationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Récupérer les coordonnées géographiques
    GeoPoint geoPoint = data['coordinates'] ?? GeoPoint(0, 0);
    
    return LocationModel(
      id: doc.id,
      name: data['name'] ?? 'Sans nom',
      latitude: geoPoint.latitude,
      longitude: geoPoint.longitude,
      address: data['address'] ?? 'Adresse non spécifiée',
      description: data['description'],
      photoUrl: data['photoUrl'],
      providerId: data['providerId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'coordinates': GeoPoint(latitude, longitude),
      'address': address,
      'description': description,
      'photoUrl': photoUrl,
      'providerId': providerId,
    };
  }
}