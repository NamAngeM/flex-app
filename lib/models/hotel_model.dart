import 'package:cloud_firestore/cloud_firestore.dart';

enum HotelCategory {
  luxe,
  affaires,
  vacances,
  economique,
  resort
}

class HotelModel {
  final String id;
  final String name;
  final String description;
  final String address;
  final GeoPoint location;
  final String photoUrl;
  final HotelCategory category;
  final Map<String, bool> services;
  final double rating;
  final int reviewCount;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final bool isActive;

  HotelModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.location,
    required this.photoUrl,
    required this.category,
    required this.services,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.metadata = const {},
    required this.createdAt,
    this.isActive = true,
  });

  // Getters pour les services
  bool get hasWifi => services['wifi'] ?? false;
  bool get hasBreakfast => services['breakfast'] ?? false;
  bool get hasParking => services['parking'] ?? false;
  bool get hasPool => services['pool'] ?? false;
  bool get hasSpa => services['spa'] ?? false;
  bool get hasGym => services['gym'] ?? false;
  bool get hasRoomService => services['roomService'] ?? false;

  // Conversion depuis/vers Firestore
  factory HotelModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return HotelModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      location: data['location'] ?? GeoPoint(0, 0),
      photoUrl: data['photoUrl'] ?? '',
      category: _categoryFromString(data['category'] ?? 'economique'),
      services: Map<String, bool>.from(data['services'] ?? {}),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      metadata: data['metadata'] ?? {},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'address': address,
      'location': location,
      'photoUrl': photoUrl,
      'category': _categoryToString(category),
      'services': services,
      'rating': rating,
      'reviewCount': reviewCount,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  // Helpers pour la conversion de l'enum
  static HotelCategory _categoryFromString(String category) {
    switch (category) {
      case 'luxe': return HotelCategory.luxe;
      case 'affaires': return HotelCategory.affaires;
      case 'vacances': return HotelCategory.vacances;
      case 'economique': return HotelCategory.economique;
      case 'resort': return HotelCategory.resort;
      default: return HotelCategory.economique;
    }
  }

  static String _categoryToString(HotelCategory category) {
    switch (category) {
      case HotelCategory.luxe: return 'luxe';
      case HotelCategory.affaires: return 'affaires';
      case HotelCategory.vacances: return 'vacances';
      case HotelCategory.economique: return 'economique';
      case HotelCategory.resort: return 'resort';
    }
  }

  // Obtenir le nom français de la catégorie
  String getCategoryName() {
    switch (category) {
      case HotelCategory.luxe: return 'Luxe';
      case HotelCategory.affaires: return 'Affaires';
      case HotelCategory.vacances: return 'Vacances';
      case HotelCategory.economique: return 'Économique';
      case HotelCategory.resort: return 'Resort';
    }
  }

  // Méthode pour vérifier si l'hôtel correspond aux critères de recherche
  bool matchesSearchCriteria({
    String? searchText,
    HotelCategory? categoryFilter,
    Map<String, bool>? requiredServices,
    double? minRating,
    double? maxPrice,
  }) {
    // Vérifier le texte de recherche
    if (searchText != null && searchText.isNotEmpty) {
      final searchLower = searchText.toLowerCase();
      if (!name.toLowerCase().contains(searchLower) &&
          !description.toLowerCase().contains(searchLower) &&
          !address.toLowerCase().contains(searchLower)) {
        return false;
      }
    }

    // Vérifier la catégorie
    if (categoryFilter != null && category != categoryFilter) {
      return false;
    }

    // Vérifier les services requis
    if (requiredServices != null) {
      for (var entry in requiredServices.entries) {
        if (entry.value && !(services[entry.key] ?? false)) {
          return false;
        }
      }
    }

    // Vérifier la note minimale
    if (minRating != null && rating < minRating) {
      return false;
    }

    return true;
  }
}