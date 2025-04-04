import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String name;
  final String providerId;
  final String categoryId;
  final String description;
  final int durationMinutes;
  final double price;
  final String? imageUrl;
  final bool isPopular;
  final DateTime createdAt;
  
  // Ces getters sont maintenus pour la compatibilité avec le code existant
  // À terme, il est recommandé d'utiliser directement les propriétés principales
  // comme providerId, categoryId et durationMinutes
  @Deprecated('Utiliser providerId à la place')
  String get provider => providerId;
  
  @Deprecated('Utiliser durationMinutes à la place')
  int get duration => durationMinutes;
  
  // Valeur fixe pour le moment, à remplacer par une implémentation réelle
  double? get rating => 4.5; 
  
  @Deprecated('Utiliser categoryId à la place')
  String get category => categoryId;
  
  ServiceModel({
    required this.id,
    required this.name,
    required this.providerId,
    required this.categoryId,
    required this.description,
    required this.durationMinutes,
    required this.price,
    this.imageUrl,
    this.isPopular = false,
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ServiceModel(
      id: doc.id,
      name: data['name'] ?? '',
      providerId: data['providerId'] ?? '',
      // Gère la rétrocompatibilité avec les anciennes données qui utilisaient 'category' au lieu de 'categoryId'
      categoryId: data['categoryId'] ?? data['category'] ?? '',
      description: data['description'] ?? '',
      durationMinutes: data['durationMinutes'] ?? 60,
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'],
      isPopular: data['isPopular'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'providerId': providerId,
      'categoryId': categoryId,
      'description': description,
      'durationMinutes': durationMinutes,
      'price': price,
      'imageUrl': imageUrl,
      'isPopular': isPopular,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ServiceModel copyWith({
    String? id,
    String? name,
    String? providerId,
    String? categoryId,
    String? description,
    int? durationMinutes,
    double? price,
    String? imageUrl,
    bool? isPopular,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      providerId: providerId ?? this.providerId,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isPopular: isPopular ?? this.isPopular,
      createdAt: this.createdAt,
    );
  }
}