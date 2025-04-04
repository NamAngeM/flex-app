import 'package:cloud_firestore/cloud_firestore.dart';

enum TableLocation {
  interieur,
  terrasse,
  salon,
  bar,
  vip
}

class TableModel {
  final String id;
  final String restaurantId;
  final String name;
  final int capacity;
  final TableLocation location;
  final bool isAvailable;
  final Map<String, dynamic> metadata;

  TableModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.capacity,
    required this.location,
    this.isAvailable = true,
    this.metadata = const {},
  });

  // Conversion depuis/vers Firestore
  factory TableModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return TableModel(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      name: data['name'] ?? '',
      capacity: data['capacity'] ?? 2,
      location: _locationFromString(data['location'] ?? 'interieur'),
      isAvailable: data['isAvailable'] ?? true,
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      'capacity': capacity,
      'location': _locationToString(location),
      'isAvailable': isAvailable,
      'metadata': metadata,
    };
  }

  // Helpers pour la conversion de l'enum
  static TableLocation _locationFromString(String location) {
    switch (location) {
      case 'interieur': return TableLocation.interieur;
      case 'terrasse': return TableLocation.terrasse;
      case 'salon': return TableLocation.salon;
      case 'bar': return TableLocation.bar;
      case 'vip': return TableLocation.vip;
      default: return TableLocation.interieur;
    }
  }

  static String _locationToString(TableLocation location) {
    switch (location) {
      case TableLocation.interieur: return 'interieur';
      case TableLocation.terrasse: return 'terrasse';
      case TableLocation.salon: return 'salon';
      case TableLocation.bar: return 'bar';
      case TableLocation.vip: return 'vip';
    }
  }

  // Obtenir le nom français de l'emplacement
  String getLocationName() {
    switch (location) {
      case TableLocation.interieur: return 'Intérieur';
      case TableLocation.terrasse: return 'Terrasse';
      case TableLocation.salon: return 'Salon';
      case TableLocation.bar: return 'Bar';
      case TableLocation.vip: return 'VIP';
    }
  }
}