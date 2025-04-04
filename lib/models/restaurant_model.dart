import 'package:cloud_firestore/cloud_firestore.dart';

enum RestaurantCategory {
  gastronomique,
  traditionnel,
  rapide,
  italien,
  asiatique,
  vegetarien,
  autre
}

class RestaurantModel {
  final String id;
  final String name;
  final String description;
  final String address;
  final GeoPoint location;
  final String photoUrl;
  final RestaurantCategory category;
  final Map<String, bool> features;
  final List<String> cuisineTypes;
  final double rating;
  final int reviewCount;
  final Map<String, dynamic> openingHours;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final bool isActive;
  final bool acceptsOnlineOrders;
  final bool acceptsReservations;
  final String phoneNumber;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.location,
    required this.photoUrl,
    required this.category,
    required this.features,
    required this.cuisineTypes,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.openingHours,
    this.metadata = const {},
    required this.createdAt,
    this.isActive = true,
    this.acceptsOnlineOrders = false,
    this.acceptsReservations = true,
    this.phoneNumber = '',
  });

  // Getters pour les fonctionnalités
  bool get hasWifi => features['wifi'] ?? false;
  bool get hasParking => features['parking'] ?? false;
  bool get hasTerrace => features['terrace'] ?? false;
  bool get isAccessible => features['accessible'] ?? false;
  bool get acceptsGroups => features['groups'] ?? false;
  bool get hasChildrenMenu => features['childrenMenu'] ?? false;

  // Conversion depuis/vers Firestore
  factory RestaurantModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return RestaurantModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      location: data['location'] ?? GeoPoint(0, 0),
      photoUrl: data['photoUrl'] ?? '',
      category: _categoryFromString(data['category'] ?? 'autre'),
      features: Map<String, bool>.from(data['features'] ?? {}),
      cuisineTypes: List<String>.from(data['cuisineTypes'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      openingHours: data['openingHours'] ?? {},
      metadata: data['metadata'] ?? {},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      acceptsOnlineOrders: data['acceptsOnlineOrders'] ?? false,
      acceptsReservations: data['acceptsReservations'] ?? true,
      phoneNumber: data['phoneNumber'] ?? '',
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
      'features': features,
      'cuisineTypes': cuisineTypes,
      'rating': rating,
      'reviewCount': reviewCount,
      'openingHours': openingHours,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'acceptsOnlineOrders': acceptsOnlineOrders,
      'acceptsReservations': acceptsReservations,
      'phoneNumber': phoneNumber,
    };
  }

  // Helpers pour la conversion de l'enum
  static RestaurantCategory _categoryFromString(String category) {
    switch (category) {
      case 'gastronomique': return RestaurantCategory.gastronomique;
      case 'traditionnel': return RestaurantCategory.traditionnel;
      case 'rapide': return RestaurantCategory.rapide;
      case 'italien': return RestaurantCategory.italien;
      case 'asiatique': return RestaurantCategory.asiatique;
      case 'vegetarien': return RestaurantCategory.vegetarien;
      case 'autre': return RestaurantCategory.autre;
      default: return RestaurantCategory.autre;
    }
  }

  static String _categoryToString(RestaurantCategory category) {
    switch (category) {
      case RestaurantCategory.gastronomique: return 'gastronomique';
      case RestaurantCategory.traditionnel: return 'traditionnel';
      case RestaurantCategory.rapide: return 'rapide';
      case RestaurantCategory.italien: return 'italien';
      case RestaurantCategory.asiatique: return 'asiatique';
      case RestaurantCategory.vegetarien: return 'vegetarien';
      case RestaurantCategory.autre: return 'autre';
    }
  }

  // Obtenir le nom français de la catégorie
  String getCategoryName() {
    switch (category) {
      case RestaurantCategory.gastronomique: return 'Gastronomique';
      case RestaurantCategory.traditionnel: return 'Traditionnel';
      case RestaurantCategory.rapide: return 'Restauration rapide';
      case RestaurantCategory.italien: return 'Italien';
      case RestaurantCategory.asiatique: return 'Asiatique';
      case RestaurantCategory.vegetarien: return 'Végétarien';
      case RestaurantCategory.autre: return 'Autre';
    }
  }

  // Méthode pour vérifier si le restaurant correspond aux critères de recherche
  bool matchesSearchCriteria({
    String? searchText,
    RestaurantCategory? categoryFilter,
    List<String>? cuisineFilters,
    Map<String, bool>? requiredFeatures,
    double? minRating,
    bool? mustAcceptReservations,
    bool? mustAcceptOnlineOrders,
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

    // Vérifier les types de cuisine
    if (cuisineFilters != null && cuisineFilters.isNotEmpty) {
      bool hasMatchingCuisine = false;
      for (var cuisine in cuisineFilters) {
        if (cuisineTypes.contains(cuisine)) {
          hasMatchingCuisine = true;
          break;
        }
      }
      if (!hasMatchingCuisine) return false;
    }

    // Vérifier les fonctionnalités requises
    if (requiredFeatures != null) {
      for (var entry in requiredFeatures.entries) {
        if (entry.value && !(features[entry.key] ?? false)) {
          return false;
        }
      }
    }

    // Vérifier la note minimale
    if (minRating != null && rating < minRating) {
      return false;
    }

    // Vérifier si accepte les réservations
    if (mustAcceptReservations == true && !acceptsReservations) {
      return false;
    }

    // Vérifier si accepte les commandes en ligne
    if (mustAcceptOnlineOrders == true && !acceptsOnlineOrders) {
      return false;
    }

    return true;
  }
}