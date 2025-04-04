import 'package:cloud_firestore/cloud_firestore.dart';

enum TableLocation {
  interieur,
  terrasse,
  salon,
  bar,
  vip
}

enum TableType {
  standard,
  bar,
  booth,
  counter,
  outdoor,
  private
}

class RestaurantTableModel {
  final String id;
  final String restaurantId;
  final String name;
  final int capacity;
  final TableLocation location;
  final TableType type;
  final bool isAvailable;
  final Map<String, dynamic> metadata;
  final Map<String, bool> features;

  RestaurantTableModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.capacity,
    required this.location,
    this.type = TableType.standard,
    this.isAvailable = true,
    this.metadata = const {},
    this.features = const {},
  });

  // Conversion depuis/vers Firestore
  factory RestaurantTableModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return RestaurantTableModel(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      name: data['name'] ?? '',
      capacity: data['capacity'] ?? 2,
      location: _locationFromString(data['location'] ?? 'interieur'),
      type: _typeFromString(data['type'] ?? 'standard'),
      isAvailable: data['isAvailable'] ?? true,
      metadata: data['metadata'] ?? {},
      features: Map<String, bool>.from(data['features'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      'capacity': capacity,
      'location': _locationToString(location),
      'type': _typeToString(type),
      'isAvailable': isAvailable,
      'metadata': metadata,
      'features': features,
    };
  }

  // Méthodes utilitaires pour la conversion des énumérations
  static TableLocation _locationFromString(String location) {
    switch (location.toLowerCase()) {
      case 'terrasse':
        return TableLocation.terrasse;
      case 'salon':
        return TableLocation.salon;
      case 'bar':
        return TableLocation.bar;
      case 'vip':
        return TableLocation.vip;
      case 'interieur':
      default:
        return TableLocation.interieur;
    }
  }

  static String _locationToString(TableLocation location) {
    switch (location) {
      case TableLocation.terrasse:
        return 'terrasse';
      case TableLocation.salon:
        return 'salon';
      case TableLocation.bar:
        return 'bar';
      case TableLocation.vip:
        return 'vip';
      case TableLocation.interieur:
      default:
        return 'interieur';
    }
  }

  static TableType _typeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'bar':
        return TableType.bar;
      case 'booth':
        return TableType.booth;
      case 'counter':
        return TableType.counter;
      case 'outdoor':
        return TableType.outdoor;
      case 'private':
        return TableType.private;
      case 'standard':
      default:
        return TableType.standard;
    }
  }

  static String _typeToString(TableType type) {
    switch (type) {
      case TableType.bar:
        return 'bar';
      case TableType.booth:
        return 'booth';
      case TableType.counter:
        return 'counter';
      case TableType.outdoor:
        return 'outdoor';
      case TableType.private:
        return 'private';
      case TableType.standard:
      default:
        return 'standard';
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