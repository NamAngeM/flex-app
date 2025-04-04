// lib/models/category_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final String? imageUrl;
  final int serviceCount;
  final DateTime createdAt;
  
  CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    this.imageUrl,
    this.serviceCount = 0,
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      iconName: data['iconName'] ?? 'category',
      imageUrl: data['imageUrl'],
      serviceCount: data['serviceCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'iconName': iconName,
      'imageUrl': imageUrl,
      'serviceCount': serviceCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    String? imageUrl,
    int? serviceCount,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      imageUrl: imageUrl ?? this.imageUrl,
      serviceCount: serviceCount ?? this.serviceCount,
      createdAt: this.createdAt,
    );
  }
}