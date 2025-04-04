// lib/services/service_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/service_model.dart';
import '../models/hotel_model.dart';
import '../services/hotel_service.dart';
import '../services/app_config.dart';

class ServiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final HotelService _hotelService = HotelService();
  final bool _devMode = AppConfig().isDevMode(); 
  
  // Récupérer tous les services
  Stream<List<ServiceModel>> getServices() {
    if (_devMode) {
      // Retourner des données simulées
      return Stream.value(_getMockServices());
    }
    
    // Créer un StreamController pour combiner les résultats de toutes les collections
    final controller = StreamController<List<ServiceModel>>();
    
    // Liste des collections à interroger
    final collections = {
      'hotels': 'cat6',
      'hospitals': 'cat1',
      'universities': 'cat3',
      'restaurants': 'cat5'
    };
    
    List<ServiceModel> allServices = [];
    int completedQueries = 0;
    
    print('Début de récupération des services depuis ${collections.length} collections');
    
    // Interroger chaque collection
    collections.forEach((collection, categoryId) {
      print('Interrogation de la collection $collection');
      _firestore
          .collection(collection)
          .get()
          .then((snapshot) {
            print('Récupéré ${snapshot.docs.length} documents de $collection');
            
            final services = snapshot.docs.map((doc) {
              Map<String, dynamic> data = doc.data();
              
              // Vérifier les données reçues
              print('Document ${doc.id} de $collection: ${data.keys.join(', ')}');
              
              // Créer un service à partir des données de la collection
              return ServiceModel(
                id: '${collection}_${doc.id}',
                name: data['name'] ?? '',
                providerId: doc.id,
                categoryId: categoryId,
                description: data['description'] ?? '',
                durationMinutes: 60, // Valeur par défaut
                price: data['price'] != null ? (data['price'] as num).toDouble() : 200,
                imageUrl: data['mainImage'] ?? data['photoUrl'] ?? '',
                isPopular: data['rating'] != null ? (data['rating'] as num) > 4.0 : false,
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );
            }).toList();
            
            print('Créé ${services.length} services à partir de $collection');
            allServices.addAll(services);
            completedQueries++;
            
            // Si toutes les requêtes sont terminées, ajouter les résultats au stream et fermer
            if (completedQueries == collections.length) {
              print('Total des services récupérés: ${allServices.length}');
              controller.add(allServices);
              controller.close();
            }
          })
          .catchError((error) {
            print('Erreur lors de la récupération des services dans $collection: $error');
            completedQueries++;
            
            // Si toutes les requêtes sont terminées, ajouter les résultats au stream et fermer
            if (completedQueries == collections.length) {
              print('Total des services récupérés (avec erreurs): ${allServices.length}');
              controller.add(allServices);
              controller.close();
            }
          });
    });
    
    return controller.stream;
  }

  // Récupérer les services populaires
  Future<List<ServiceModel>> getPopularServices() async {
    if (_devMode) {
      // Retourner des données simulées
      return _getMockServices().where((service) => service.isPopular).toList();
    }
    
    try {
      // Obtenir tous les services
      final services = await getServices().first;
      print('Récupéré ${services.length} services pour filtrer les populaires');
      
      // Filtrer les services populaires (avec un rating élevé)
      final popularServices = services.where((service) => service.isPopular).take(5).toList();
      print('Nombre de services populaires: ${popularServices.length}');
      return popularServices;
    } catch (e) {
      print('Erreur lors de la récupération des services populaires: $e');
      return [];
    }
  }
  
  // Récupérer les services récemment consultés
  Future<List<ServiceModel>> getRecentServices() async {
    if (_devMode) {
      // Retourner quelques services simulés comme récemment consultés
      return _getMockServices().take(3).toList();
    }
    
    try {
      // Obtenir tous les services
      final services = await getServices().first;
      print('Récupéré ${services.length} services pour les récents');
      
      // Prendre les 3 premiers services (ou moins s'il y en a moins)
      final recentServices = services.take(3).toList();
      print('Nombre de services récents: ${recentServices.length}');
      return recentServices;
    } catch (e) {
      print('Erreur lors de la récupération des services récents: $e');
      return [];
    }
  }

  // Rechercher des services par nom, description ou catégorie
  Future<List<ServiceModel>> searchServices(String query) async {
    try {
      if (_devMode) {
        // Retourner des données simulées filtrées
        query = query.toLowerCase();
        final filteredResults = _getMockServices()
            .where((service) => 
                service.name.toLowerCase().contains(query) || 
                service.description.toLowerCase().contains(query) ||
                service.categoryId.toLowerCase().contains(query))
            .toList();
            
        // Si aucun résultat, retourner tous les services
        if (filteredResults.isEmpty) {
          print('Aucun résultat trouvé pour "$query", retour de tous les services');
          return _getMockServices();
        }
        
        return filteredResults;
      }
      
      query = query.toLowerCase().trim();
      print('Recherche de services contenant "$query"');
      
      // Définition des collections avec leurs catégories et termes de recherche associés
      final collections = {
        'hotels': {
          'categoryId': 'cat6',
          'categoryName': 'Hôtels',
          'searchTerms': ['hotel', 'hôtel', 'hôtels', 'logement', 'chambre', 'séjour', 'nuit', 'hebergement', 'hébergement', 'auberge', 'pension', 'gîte']
        },
        'hospitals': {
          'categoryId': 'cat1',
          'categoryName': 'Santé',
          'searchTerms': ['hopital', 'hôpital', 'hôpitaux', 'clinique', 'médical', 'santé', 'médecin', 'docteur', 'sante', 'medical', 'medecin', 'urgence', 'soins']
        },
        'universities': {
          'categoryId': 'cat3',
          'categoryName': 'Éducation',
          'searchTerms': ['universite', 'université', 'universités', 'école', 'ecole', 'formation', 'étude', 'études', 'education', 'éducation', 'etude', 'etudes', 'cours', 'enseignement']
        },
        'restaurants': {
          'categoryId': 'cat5',
          'categoryName': 'Restaurants',
          'searchTerms': ['restaurant', 'restaurants', 'repas', 'dîner', 'diner', 'dejeuner', 'déjeuner', 'cuisine', 'manger', 'gastronomie', 'resto', 'bar', 'café', 'bistrot']
        }
      };
      
      // Vérifier si la requête correspond à une catégorie spécifique
      List<String> collectionsToSearch = [];
      
      // Vérifier si la requête correspond à un terme de recherche
      for (var entry in collections.entries) {
        final searchTerms = entry.value['searchTerms'] as List<String>;
        for (var term in searchTerms) {
          if (query == term || query.contains(term) || term.contains(query)) {
            collectionsToSearch.add(entry.key);
            print('La requête "$query" correspond à la catégorie ${entry.value['categoryName']}');
            break;
          }
        }
      }
      
      // Si aucune catégorie spécifique n'est identifiée, rechercher dans toutes les collections
      if (collectionsToSearch.isEmpty) {
        collectionsToSearch = collections.keys.toList();
        print('Aucune catégorie spécifique identifiée, recherche dans toutes les collections');
      }
      
      List<ServiceModel> allServices = [];
      
      // Interroger chaque collection pertinente
      for (var collectionName in collectionsToSearch) {
        final collectionInfo = collections[collectionName]!;
        final categoryId = collectionInfo['categoryId'] as String;
        final categoryName = collectionInfo['categoryName'] as String;
        
        try {
          print('Interrogation de la collection $collectionName (catégorie: $categoryName)');
          
          // Récupérer tous les documents de la collection
          final snapshot = await _firestore.collection(collectionName).get();
          print('Récupéré ${snapshot.docs.length} documents de $collectionName');
          
          if (snapshot.docs.isEmpty) {
            print('Aucun document trouvé dans la collection $collectionName');
            continue;
          }
          
          final services = snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            
            // Vérifier les données reçues
            print('Document ${doc.id} de $collectionName: ${data.keys.join(', ')}');
            
            String name = data['name'] ?? '';
            String description = data['description'] ?? '';
            
            // Créer un service à partir des données de la collection
            return ServiceModel(
              id: '${collectionName}_${doc.id}',
              name: name,
              providerId: doc.id,
              categoryId: categoryId,
              description: description,
              durationMinutes: 60, // Valeur par défaut
              price: data['price'] != null ? (data['price'] as num).toDouble() : 0.0,
              imageUrl: data['mainImage'] ?? data['photoUrl'] ?? '',
              isPopular: data['rating'] != null ? (data['rating'] as num) > 4.0 : false,
              createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList();
          
          print('Créé ${services.length} services à partir de $collectionName');
          allServices.addAll(services);
        } catch (e) {
          print('Erreur lors de la récupération des services dans $collectionName: $e');
        }
      }
      
      print('Total des services récupérés: ${allServices.length}');
      
      // Si la recherche est spécifique à une catégorie (une seule collection) et qu'on a des résultats,
      // retourner tous les services de cette catégorie
      if (collectionsToSearch.length == 1 && allServices.isNotEmpty) {
        final categoryName = collections[collectionsToSearch.first]!['categoryName'] as String;
        print('Recherche spécifique à la catégorie $categoryName, retour de tous les services de cette catégorie (${allServices.length})');
        return allServices;
      }
      
      // Sinon, filtrer les services qui correspondent à la requête
      if (query.isNotEmpty && query.length > 2) {
        final results = allServices.where((service) => 
            service.name.toLowerCase().contains(query) || 
            service.description.toLowerCase().contains(query)).toList();
        
        print('Nombre de résultats après filtrage: ${results.length}');
        
        // Si on a des résultats après filtrage, les retourner
        if (results.isNotEmpty) {
          return results;
        }
      }
      
      // Si aucun résultat après filtrage ou si la requête est trop courte,
      // retourner tous les services récupérés
      print('Retour de tous les services récupérés (${allServices.length})');
      return allServices;
    } catch (e) {
      print('Erreur lors de la recherche de services: $e');
      // En cas d'erreur, essayer de récupérer tous les services
      try {
        final services = await getServices().first;
        print('Récupération de secours: ${services.length} services');
        return services;
      } catch (e) {
        print('Erreur lors de la récupération de tous les services: $e');
        return [];
      }
    }
  }
  
  // Récupérer un service par ID
  Future<ServiceModel?> getServiceById(String id) async {
    if (_devMode) {
      // Retourner un service simulé correspondant à l'ID
      return _getMockServices().firstWhere(
        (service) => service.id == id,
        orElse: () => _getMockServices().first,
      );
    }
    
    try {
      print('Récupération du service avec ID: $id');
      
      // Déterminer la collection à partir de l'ID
      String collection = '';
      String originalId = '';
      
      if (id.startsWith('hotels_')) {
        collection = 'hotels';
        originalId = id.substring(7); // Enlever 'hotels_'
      } else if (id.startsWith('hospitals_')) {
        collection = 'hospitals';
        originalId = id.substring(10); // Enlever 'hospitals_'
      } else if (id.startsWith('universities_')) {
        collection = 'universities';
        originalId = id.substring(13); // Enlever 'universities_'
      } else if (id.startsWith('restaurants_')) {
        collection = 'restaurants';
        originalId = id.substring(12); // Enlever 'restaurants_'
      } else {
        print('Format d\'ID non reconnu: $id');
        // Si l'ID ne correspond à aucune collection, essayer de le trouver dans les services
        final services = await getServices().first;
        final service = services.firstWhere(
          (service) => service.id == id,
          orElse: () => services.isNotEmpty ? services.first : _getMockServices().first,
        );
        return service;
      }
      
      print('Recherche dans la collection $collection avec ID $originalId');
      
      // Récupérer le document de la collection
      final doc = await _firestore.collection(collection).doc(originalId).get();
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data()!;
        print('Document trouvé: ${data.keys.join(', ')}');
        
        // Déterminer la catégorie en fonction de la collection
        String categoryId = '';
        if (collection == 'hotels') categoryId = 'cat6';
        else if (collection == 'hospitals') categoryId = 'cat1';
        else if (collection == 'universities') categoryId = 'cat3';
        else if (collection == 'restaurants') categoryId = 'cat5';
        
        return ServiceModel(
          id: id,
          name: data['name'] ?? '',
          providerId: doc.id,
          categoryId: categoryId,
          description: data['description'] ?? '',
          durationMinutes: 24, // Valeur par défaut
          price: data['price'] != null ? (data['price'] as num).toDouble() : 0.0,
          imageUrl: data['mainImage'] ?? data['photoUrl'] ?? '',
          isPopular: data['rating'] != null ? (data['rating'] as num) > 4.0 : false,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      } else {
        print('Document non trouvé dans $collection avec ID $originalId');
        return null;
      }
    } catch (e) {
      print('Erreur lors de la récupération du service par ID: $e');
      return null;
    }
  }
  
  // Récupérer les services par catégorie
  Future<List<ServiceModel>> getServicesByCategory(String categoryId) async {
    try {
      print('Récupération des services pour la catégorie: $categoryId');
      
      // Vérifier si c'est la catégorie Hôtels
      if (categoryId == 'cat6') {
        // Pour les hôtels, nous utilisons un traitement spécial
        // dans l'écran CategoryServicesScreen
        return [];
      }

      if (_devMode) {
        return _getMockServices().where((service) => service.categoryId == categoryId).toList();
      }

      // Déterminer la collection en fonction de la catégorie
      String collection = '';
      switch (categoryId) {
        case 'cat1': // Santé
          collection = 'hospitals';
          break;
        case 'cat3': // Éducation
          collection = 'universities';
          break;
        case 'cat5': // Bien-être/Restaurants
          collection = 'restaurants';
          break;
        case 'cat6': // Hôtels
          collection = 'hotels';
          break;
        default:
          // Si la catégorie n'est pas reconnue, retourner des données fictives
          print('Catégorie non reconnue: $categoryId, utilisation de données fictives');
          return _getMockServicesForCategory(categoryId);
      }

      print('Interrogation de la collection $collection pour la catégorie $categoryId');
      final snapshot = await _firestore.collection(collection).get();
      print('Récupéré ${snapshot.docs.length} documents de $collection');
      
      if (snapshot.docs.isEmpty) {
        print('Aucun document trouvé dans la collection $collection');
        return _getMockServicesForCategory(categoryId);
      }
      
      List<ServiceModel> services = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        print('Document ${doc.id} de $collection: ${data.keys.join(', ')}');
        
        return ServiceModel(
          id: '${collection}_${doc.id}',
          name: data['name'] ?? '',
          providerId: doc.id,
          categoryId: categoryId,
          description: data['description'] ?? '',
          durationMinutes: 60, // Valeur par défaut
          price: data['price'] != null ? (data['price'] as num).toDouble() : 0.0,
          imageUrl: data['mainImage'] ?? data['photoUrl'] ?? '',
          isPopular: data['rating'] != null ? (data['rating'] as num) > 4.0 : false,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
      
      print('Créé ${services.length} services pour la catégorie $categoryId');
      
      // Si aucun service n'est trouvé, retourner des données fictives pour cette catégorie
      if (services.isEmpty) {
        print('Aucun service trouvé pour la catégorie $categoryId, utilisation de données fictives');
        return _getMockServicesForCategory(categoryId);
      }
      
      return services;
    } catch (e) {
      print('Erreur lors de la récupération des services par catégorie: $e');
      // En cas d'erreur, retourner des données fictives pour cette catégorie
      return _getMockServicesForCategory(categoryId);
    }
  }
  
  // Données fictives pour une catégorie spécifique
  List<ServiceModel> _getMockServicesForCategory(String categoryId) {
    // Filtrer les services fictifs par catégorie
    List<ServiceModel> categoryServices = _getMockServices()
        .where((service) => service.categoryId == categoryId)
        .toList();
    
    // Si aucun service fictif n'existe pour cette catégorie, en créer quelques-uns
    if (categoryServices.isEmpty) {
      String categoryName = '';
      String imagePrefix = '';
      
      switch (categoryId) {
        case 'cat1': // Santé
          categoryName = 'Santé';
          imagePrefix = 'medical';
          categoryServices = [
            ServiceModel(
              id: 'service_sante_1',
              name: 'Consultation médicale',
              description: 'Consultation générale avec un médecin',
              price: 50.0,
              durationMinutes: 20,
              categoryId: categoryId,
              providerId: 'provider1',
              imageUrl: 'https://example.com/${imagePrefix}_1.jpg',
            ),
            ServiceModel(
              id: 'service_sante_2',
              name: 'Analyse sanguine',
              description: 'Analyse complète du sang',
              price: 35.0,
              durationMinutes: 15,
              categoryId: categoryId,
              providerId: 'provider1',
              imageUrl: 'https://example.com/${imagePrefix}_2.jpg',
            ),
          ];
          break;
        // Autres cas...
        default:
          categoryServices = [];
      }
    }
    
    return categoryServices;
  }
  
  // Données fictives pour le développement
  List<ServiceModel> _getMockServices() {
    return [
      ServiceModel(
        id: '1',
        name: 'Consultation médicale',
        providerId: 'provider1',
        categoryId: 'cat1',
        description: 'Consultation générale avec un médecin',
        durationMinutes: 20,
        price: 50.0,
        imageUrl: 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528',
        isPopular: true,
      ),
      // Autres services fictifs...
    ];
  }
}