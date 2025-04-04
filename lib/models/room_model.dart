import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomType {
  standard,
  deluxe,
  suite,
  familiale,
  executive
}

enum BedType {
  simple,
  double,
  queen,
  king,
  twin
}

class RoomModel {
  final String id;
  final String hotelId;
  final String name;
  final String description;
  final RoomType type;
  final BedType bedType;
  final int maxOccupancy;
  final double price;
  final double priceWeekend;
  final List<String> photoUrls;
  final Map<String, bool> features;
  final bool isAvailable;
  final Map<String, dynamic> metadata;

  RoomModel({
    required this.id,
    required this.hotelId,
    required this.name,
    required this.description,
    required this.type,
    required this.bedType,
    required this.maxOccupancy,
    required this.price,
    this.priceWeekend = 0.0,
    required this.photoUrls,
    required this.features,
    this.isAvailable = true,
    this.metadata = const {},
  });

  // Getters pour les fonctionnalités
  bool get hasAirConditioning => features['airConditioning'] ?? false;
  bool get hasMinibar => features['minibar'] ?? false;
  bool get hasTv => features['tv'] ?? false;
  bool get hasSafe => features['safe'] ?? false;
  bool get hasBalcony => features['balcony'] ?? false;
  bool get hasPrivateBathroom => features['privateBathroom'] ?? true;

  // Conversion depuis/vers Firestore
  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return RoomModel(
      id: doc.id,
      hotelId: data['hotelId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: _roomTypeFromString(data['type'] ?? 'standard'),
      bedType: _bedTypeFromString(data['bedType'] ?? 'double'),
      maxOccupancy: data['maxOccupancy'] ?? 2,
      price: (data['price'] ?? 0.0).toDouble(),
      priceWeekend: (data['priceWeekend'] ?? 0.0).toDouble(),
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      features: Map<String, bool>.from(data['features'] ?? {}),
      isAvailable: data['isAvailable'] ?? true,
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'hotelId': hotelId,
      'name': name,
      'description': description,
      'type': _roomTypeToString(type),
      'bedType': _bedTypeToString(bedType),
      'maxOccupancy': maxOccupancy,
      'price': price,
      'priceWeekend': priceWeekend,
      'photoUrls': photoUrls,
      'features': features,
      'isAvailable': isAvailable,
      'metadata': metadata,
    };
  }

  // Helpers pour la conversion des enums
  static RoomType _roomTypeFromString(String type) {
    switch (type) {
      case 'standard': return RoomType.standard;
      case 'deluxe': return RoomType.deluxe;
      case 'suite': return RoomType.suite;
      case 'familiale': return RoomType.familiale;
      case 'executive': return RoomType.executive;
      default: return RoomType.standard;
    }
  }

  static String _roomTypeToString(RoomType type) {
    switch (type) {
      case RoomType.standard: return 'standard';
      case RoomType.deluxe: return 'deluxe';
      case RoomType.suite: return 'suite';
      case RoomType.familiale: return 'familiale';
      case RoomType.executive: return 'executive';
    }
  }

  static BedType _bedTypeFromString(String type) {
    switch (type) {
      case 'simple': return BedType.simple;
      case 'double': return BedType.double;
      case 'queen': return BedType.queen;
      case 'king': return BedType.king;
      case 'twin': return BedType.twin;
      default: return BedType.double;
    }
  }

  static String _bedTypeToString(BedType type) {
    switch (type) {
      case BedType.simple: return 'simple';
      case BedType.double: return 'double';
      case BedType.queen: return 'queen';
      case BedType.king: return 'king';
      case BedType.twin: return 'twin';
    }
  }

  // Obtenir le nom français du type de chambre
  String getRoomTypeName() {
    switch (type) {
      case RoomType.standard: return 'Standard';
      case RoomType.deluxe: return 'Deluxe';
      case RoomType.suite: return 'Suite';
      case RoomType.familiale: return 'Familiale';
      case RoomType.executive: return 'Executive';
    }
  }

  // Obtenir le nom français du type de lit
  String getBedTypeName() {
    switch (bedType) {
      case BedType.simple: return 'Lit simple';
      case BedType.double: return 'Lit double';
      case BedType.queen: return 'Lit Queen Size';
      case BedType.king: return 'Lit King Size';
      case BedType.twin: return 'Lits jumeaux';
    }
  }

  // Méthode pour vérifier si la chambre correspond aux critères de recherche
  bool matchesSearchCriteria({
    RoomType? typeFilter,
    BedType? bedTypeFilter,
    int? minOccupancy,
    double? maxPrice,
    Map<String, bool>? requiredFeatures,
  }) {
    // Vérifier le type de chambre
    if (typeFilter != null && type != typeFilter) {
      return false;
    }

    // Vérifier le type de lit
    if (bedTypeFilter != null && bedType != bedTypeFilter) {
      return false;
    }

    // Vérifier l'occupation minimale
    if (minOccupancy != null && maxOccupancy < minOccupancy) {
      return false;
    }

    // Vérifier le prix maximum
    if (maxPrice != null && price > maxPrice) {
      return false;
    }

    // Vérifier les fonctionnalités requises
    if (requiredFeatures != null) {
      for (var entry in requiredFeatures.entries) {
        if (entry.value && !(features[entry.key] ?? false)) {
          return false;
        }
      }
    }

    return true;
  }
}