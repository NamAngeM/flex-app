// lib/services/category_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';
import '../services/app_config.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'categories';
  final bool _devMode = AppConfig().isDevMode(); // Utiliser AppConfig pour la cohérence

  // Récupérer toutes les catégories
  Stream<List<CategoryModel>> getCategories() {
    try {
      if (_devMode) {
        // Retourner des données simulées
        print('Mode développement: retour des catégories fictives');
        return Stream.value(getMockCategories());
      }
      
      print('Récupération des catégories depuis Firestore');
      return _firestore
          .collection(_collection)
          .orderBy('name')
          .snapshots()
          .map((snapshot) {
            print('Snapshot de catégories reçu: ${snapshot.docs.length} documents');
            return snapshot.docs
                .map((doc) => CategoryModel.fromFirestore(doc))
                .toList();
          })
          .handleError((error) {
            print('Erreur dans le stream de catégories: $error');
            // En cas d'erreur dans le stream, retourner les catégories fictives
            return getMockCategories();
          });
    } catch (e) {
      print('Exception dans getCategories: $e');
      // Retourner un stream avec les catégories fictives en cas d'erreur
      return Stream.value(getMockCategories());
    }
  }
  
  // Version synchrone pour obtenir directement les catégories (utile pour éviter les problèmes de stream)
  List<CategoryModel> getCategoriesSync() {
    if (_devMode) {
      return getMockCategories();
    }
    
    // En mode production, on retourne quand même les données fictives
    // pour éviter de bloquer l'interface en attendant Firestore
    return getMockCategories();
  }

  // Récupérer une catégorie par ID
  Future<CategoryModel?> getCategoryById(String id) async {
    if (_devMode) {
      // Retourner une catégorie simulée correspondant à l'ID
      return getMockCategories().firstWhere(
        (category) => category.id == id,
        orElse: () => getMockCategories().first,
      );
    }
    
    final doc = await _firestore.collection(_collection).doc(id).get();
    
    if (doc.exists) {
      return CategoryModel.fromFirestore(doc);
    }
    return null;
  }
  
  // Ajouter une nouvelle catégorie
  Future<String> addCategory(CategoryModel category) async {
    if (_devMode) {
      // Simuler l'ajout d'une catégorie
      return 'new-category-id';
    }
    
    final docRef = await _firestore.collection(_collection).add(category.toMap());
    return docRef.id;
  }
  
  // Mettre à jour une catégorie
  Future<void> updateCategory(CategoryModel category) async {
    if (_devMode) {
      // Simuler la mise à jour d'une catégorie
      return;
    }
    
    await _firestore
        .collection(_collection)
        .doc(category.id)
        .update(category.toMap());
  }
  
  // Supprimer une catégorie
  Future<void> deleteCategory(String categoryId) async {
    if (_devMode) {
      // Simuler la suppression d'une catégorie
      return;
    }
    
    await _firestore.collection(_collection).doc(categoryId).delete();
  }
  
  // Données fictives pour le mode développement
  List<CategoryModel> getMockCategories() {
    return [
      CategoryModel(
        id: 'cat1',
        name: 'Santé',
        description: 'Services médicaux et de santé',
        iconName: 'medical_services',
        imageUrl: 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528',
        serviceCount: 8,
      ),
      CategoryModel(
        id: 'cat2',
        name: 'Beauté',
        description: 'Services de beauté et de bien-être',
        iconName: 'spa',
        imageUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035',
        serviceCount: 12,
      ),
      CategoryModel(
        id: 'cat3',
        name: 'Éducation',
        description: 'Services éducatifs et de formation',
        iconName: 'school',
        imageUrl: 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b',
        serviceCount: 5,
      ),
      CategoryModel(
        id: 'cat4',
        name: 'Administration',
        description: 'Services administratifs et légaux',
        iconName: 'business',
        imageUrl: 'https://images.unsplash.com/photo-1450101499163-c8848c66ca85',
        serviceCount: 3,
      ),
      CategoryModel(
        id: 'cat5',
        name: 'Bien-être',
        description: 'Services de relaxation et de bien-être',
        iconName: 'self_improvement',
        imageUrl: 'https://images.unsplash.com/photo-1544161515-4ab6ce6db874',
        serviceCount: 7,
      ),
      CategoryModel(
        id: 'cat6',
        name: 'Hôtels',
        description: 'Réservation de chambres d\'hôtel',
        iconName: 'hotel',
        imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945',
        serviceCount: 10,
      ),
    ];
  }
}