import 'package:cloud_firestore/cloud_firestore.dart';

enum ReviewCategory {
  cleanliness,
  comfort,
  location,
  service,
  value
}

class HotelReviewModel {
  final String id;
  final String userId;
  final String hotelId;
  final String? roomId;
  final String bookingId;
  final String comment;
  final Map<ReviewCategory, double> categoryRatings;
  final double overallRating;
  final List<String> photoUrls;
  final DateTime stayDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isVerifiedStay;
  final bool isActive;
  final Map<String, dynamic> metadata;

  HotelReviewModel({
    required this.id,
    required this.userId,
    required this.hotelId,
    this.roomId,
    required this.bookingId,
    required this.comment,
    required this.categoryRatings,
    required this.overallRating,
    this.photoUrls = const [],
    required this.stayDate,
    required this.createdAt,
    this.updatedAt,
    this.isVerifiedStay = true,
    this.isActive = true,
    this.metadata = const {},
  });

  // Getters pour les notes par catégorie
  double get cleanlinessRating => categoryRatings[ReviewCategory.cleanliness] ?? 0.0;
  double get comfortRating => categoryRatings[ReviewCategory.comfort] ?? 0.0;
  double get locationRating => categoryRatings[ReviewCategory.location] ?? 0.0;
  double get serviceRating => categoryRatings[ReviewCategory.service] ?? 0.0;
  double get valueRating => categoryRatings[ReviewCategory.value] ?? 0.0;

  // Conversion depuis/vers Firestore
  factory HotelReviewModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Convertir les notes par catégorie
    Map<ReviewCategory, double> categoryRatings = {};
    Map<String, dynamic> ratingsData = data['categoryRatings'] ?? {};
    
    ratingsData.forEach((key, value) {
      ReviewCategory? category = _reviewCategoryFromString(key);
      if (category != null) {
        categoryRatings[category] = (value as num).toDouble();
      }
    });
    
    return HotelReviewModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      hotelId: data['hotelId'] ?? '',
      roomId: data['roomId'],
      bookingId: data['bookingId'] ?? '',
      comment: data['comment'] ?? '',
      categoryRatings: categoryRatings,
      overallRating: (data['overallRating'] ?? 0.0).toDouble(),
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      stayDate: (data['stayDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      isVerifiedStay: data['isVerifiedStay'] ?? true,
      isActive: data['isActive'] ?? true,
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    // Convertir les notes par catégorie
    Map<String, double> categoryRatingsMap = {};
    categoryRatings.forEach((key, value) {
      categoryRatingsMap[_reviewCategoryToString(key)] = value;
    });
    
    return {
      'userId': userId,
      'hotelId': hotelId,
      'roomId': roomId,
      'bookingId': bookingId,
      'comment': comment,
      'categoryRatings': categoryRatingsMap,
      'overallRating': overallRating,
      'photoUrls': photoUrls,
      'stayDate': Timestamp.fromDate(stayDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isVerifiedStay': isVerifiedStay,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  // Helpers pour la conversion des enums
  static ReviewCategory? _reviewCategoryFromString(String category) {
    switch (category) {
      case 'cleanliness': return ReviewCategory.cleanliness;
      case 'comfort': return ReviewCategory.comfort;
      case 'location': return ReviewCategory.location;
      case 'service': return ReviewCategory.service;
      case 'value': return ReviewCategory.value;
      default: return null;
    }
  }

  static String _reviewCategoryToString(ReviewCategory category) {
    switch (category) {
      case ReviewCategory.cleanliness: return 'cleanliness';
      case ReviewCategory.comfort: return 'comfort';
      case ReviewCategory.location: return 'location';
      case ReviewCategory.service: return 'service';
      case ReviewCategory.value: return 'value';
    }
  }

  // Obtenir le nom français de la catégorie
  static String getCategoryName(ReviewCategory category) {
    switch (category) {
      case ReviewCategory.cleanliness: return 'Propreté';
      case ReviewCategory.comfort: return 'Confort';
      case ReviewCategory.location: return 'Emplacement';
      case ReviewCategory.service: return 'Service';
      case ReviewCategory.value: return 'Rapport qualité-prix';
    }
  }

  // Vérifier si l'avis peut être modifié (48h après création)
  bool canBeEdited() {
    final now = DateTime.now();
    final editDeadline = createdAt.add(Duration(hours: 48));
    return now.isBefore(editDeadline) && isActive;
  }

  // Vérifier si l'avis peut être supprimé (7 jours après création)
  bool canBeDeleted() {
    final now = DateTime.now();
    final deleteDeadline = createdAt.add(Duration(days: 7));
    return now.isBefore(deleteDeadline) && isActive;
  }
}