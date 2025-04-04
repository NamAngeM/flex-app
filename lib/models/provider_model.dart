// lib/models/provider_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final List<String>? specialties;
  final double? rating;
  final DateTime createdAt;
  final String? description;
  final String? address;
  final String? phoneNumber;
  final String? category;
  final String? city;

  ProviderModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.specialties,
    this.rating,
    DateTime? createdAt,
    this.description,
    this.address,
    this.phoneNumber,
    this.category,
    this.city,
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory ProviderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Déterminer le type de prestataire en fonction de la collection
    List<String>? specialties;
    String collectionType = '';
    
    if (doc.reference.path.contains('hotels')) {
      collectionType = 'Hôtel';
      specialties = ['Hébergement'];
    } else if (doc.reference.path.contains('hospitals')) {
      collectionType = 'Hôpital';
      specialties = ['Soins médicaux'];
    } else if (doc.reference.path.contains('universities')) {
      collectionType = 'Université';
      specialties = ['Éducation'];
    } else if (doc.reference.path.contains('restaurants')) {
      collectionType = 'Restaurant';
      specialties = ['Restauration'];
    }
    
    // Si des spécialités sont définies dans les données, les utiliser
    if (data['specialties'] != null) {
      specialties = List<String>.from(data['specialties']);
    }
    
    // Utiliser l'image principale si disponible, sinon utiliser la première image de la liste
    String? photoUrl = data['photoUrl'] ?? data['mainImage'];
    if (photoUrl == null && data['images'] != null && (data['images'] as List).isNotEmpty) {
      photoUrl = (data['images'] as List)[0];
    }
    
    return ProviderModel(
      id: doc.id,
      name: data['fullName'] ?? data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phoneNumber'] ?? data['phone'] ?? '',
      phoneNumber: data['phoneNumber'] ?? data['phone'] ?? '',
      photoUrl: photoUrl,
      specialties: specialties,
      rating: data['rating']?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'],
      address: data['address'],
      category: data['category'] ?? collectionType,
      city: data['city'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'phoneNumber': phoneNumber ?? phone,
      'photoUrl': photoUrl,
      'specialties': specialties,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
      'description': description,
      'address': address,
      'category': category,
      'city': city,
    };
  }
}