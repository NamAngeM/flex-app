import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { client, provider }

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  String? photoUrl;
  final UserRole role;
  final String phoneNumber;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  
  // Add getters for compatibility with existing code
  String get id => uid;
  String get firstName => fullName.split(' ').first;
  String get displayName => fullName;
  
  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    this.photoUrl,
    required this.role,
    required this.phoneNumber,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
  }) : 
    this.preferences = preferences ?? {},
    this.createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Déterminer le rôle à partir de la valeur stockée dans Firestore de manière plus robuste
    UserRole userRole;
    String roleStr = data['role']?.toString().toLowerCase() ?? '';
    if (roleStr.contains('provider')) {
      userRole = UserRole.provider;
    } else {
      userRole = UserRole.client;
    }
    
    // Convertir Timestamp en DateTime avec gestion des valeurs nulles
    DateTime createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else {
      createdAt = DateTime.now();
    }
    
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      photoUrl: data['photoUrl'],
      role: userRole,
      phoneNumber: data['phoneNumber'] ?? '',
      preferences: data['preferences'] ?? {},
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'photoUrl': photoUrl,
      'role': role == UserRole.provider ? 'provider' : 'client', // Format standardisé
      'phoneNumber': phoneNumber,
      'preferences': preferences,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? fullName,
    String? photoUrl,
    String? phoneNumber,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      uid: this.uid,
      email: this.email,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      preferences: preferences ?? this.preferences,
      createdAt: this.createdAt,
    );
  }
}