// lib/services/provider_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/provider_model.dart';
import 'app_config.dart';

class ProviderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final bool _devMode = AppConfig().isDevMode();

  // Obtenir un prestataire par son ID
  Future<ProviderModel?> getProviderById(String providerId) async {
    if (_devMode) {
      // Retourner des données simulées
      return _getMockProviderById(providerId);
    }

    // Déterminer la collection en fonction du préfixe de l'ID
    final collection = _getCollectionFromId(providerId);
    
    final snapshot = await _firestore
        .collection(collection)
        .doc(providerId)
        .get();
        
    if (snapshot.exists) {
      return ProviderModel.fromFirestore(snapshot);
    } else {
      return null;
    }
  }

  // Rechercher des prestataires par nom ou spécialité
  Stream<List<ProviderModel>> searchProviders(String query) {
    if (_devMode) {
      // Retourner des données simulées filtrées
      query = query.toLowerCase();
      final filteredResults = _getMockProviders()
          .where((provider) => 
              provider.name.toLowerCase().contains(query) || 
              (provider.specialties?.any((specialty) => 
                  specialty.toLowerCase().contains(query)) ?? false))
          .toList();
          
      // Si aucun résultat, retourner tous les prestataires
      if (filteredResults.isEmpty) {
        print('Aucun résultat trouvé pour "$query", retour de tous les prestataires');
        return Stream.value(_getMockProviders());
      }
      
      return Stream.value(filteredResults);
    }
    
    query = query.toLowerCase();
    
    // Créer un StreamController pour combiner les résultats de toutes les collections
    final controller = StreamController<List<ProviderModel>>();
    
    // Liste des collections à interroger
    final collections = ['hotels', 'hospitals', 'universities', 'restaurants'];
    List<ProviderModel> allProviders = [];
    int completedQueries = 0;
    
    // Interroger chaque collection
    for (final collection in collections) {
      _firestore
          .collection(collection)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get()
          .then((snapshot) {
            final providers = snapshot.docs
                .map((doc) => ProviderModel.fromFirestore(doc))
                .toList();
            allProviders.addAll(providers);
            completedQueries++;
            
            // Si toutes les requêtes sont terminées, ajouter les résultats au stream et fermer
            if (completedQueries == collections.length) {
              controller.add(allProviders);
              controller.close();
            }
          })
          .catchError((error) {
            print('Erreur lors de la recherche dans $collection: $error');
            completedQueries++;
            
            // Si toutes les requêtes sont terminées, ajouter les résultats au stream et fermer
            if (completedQueries == collections.length) {
              controller.add(allProviders);
              controller.close();
            }
          });
    }
    
    return controller.stream;
  }

  // Obtenir tous les prestataires
  Stream<List<ProviderModel>> getProviders() {
    if (_devMode) {
      // Retourner des données simulées
      return Stream.value(_getMockProviders());
    }

    // Créer un StreamController pour combiner les résultats de toutes les collections
    final controller = StreamController<List<ProviderModel>>();
    
    // Liste des collections à interroger
    final collections = ['hotels', 'hospitals', 'universities', 'restaurants'];
    List<ProviderModel> allProviders = [];
    int completedQueries = 0;
    
    // Interroger chaque collection
    for (final collection in collections) {
      _firestore
          .collection(collection)
          .get()
          .then((snapshot) {
            final providers = snapshot.docs
                .map((doc) => ProviderModel.fromFirestore(doc))
                .toList();
            allProviders.addAll(providers);
            completedQueries++;
            
            // Si toutes les requêtes sont terminées, ajouter les résultats au stream et fermer
            if (completedQueries == collections.length) {
              controller.add(allProviders);
              controller.close();
            }
          })
          .catchError((error) {
            print('Erreur lors de la récupération des prestataires dans $collection: $error');
            completedQueries++;
            
            // Si toutes les requêtes sont terminées, ajouter les résultats au stream et fermer
            if (completedQueries == collections.length) {
              controller.add(allProviders);
              controller.close();
            }
          });
    }
    
    return controller.stream;
  }

  // Obtenir les prestataires par service
  Stream<List<ProviderModel>> getProvidersByService(String serviceId) {
    if (_devMode) {
      // Retourner des données simulées filtrées par service
      return Stream.value(_getMockProvidersByService(serviceId));
    }

    // Déterminer la collection en fonction du type de service
    String collection;
    if (serviceId.startsWith('hotel_')) {
      collection = 'hotels';
    } else if (serviceId.startsWith('hospital_')) {
      collection = 'hospitals';
    } else if (serviceId.startsWith('university_')) {
      collection = 'universities';
    } else if (serviceId.startsWith('restaurant_')) {
      collection = 'restaurants';
    } else {
      // Si le préfixe n'est pas reconnu, chercher dans toutes les collections
      return getProviders();
    }

    return _firestore
        .collection(collection)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ProviderModel.fromFirestore(doc))
              .toList();
        });
  }

  // Déterminer la collection en fonction de l'ID
  String _getCollectionFromId(String id) {
    if (id.startsWith('hotel_')) {
      return 'hotels';
    } else if (id.startsWith('hospital_')) {
      return 'hospitals';
    } else if (id.startsWith('university_')) {
      return 'universities';
    } else if (id.startsWith('restaurant_')) {
      return 'restaurants';
    } else {
      // Par défaut, utiliser la collection providers
      return 'providers';
    }
  }

  // Données simulées pour le développement
  ProviderModel? _getMockProviderById(String providerId) {
    final providers = _getMockProviders();
    try {
      return providers.firstWhere((provider) => provider.id == providerId);
    } catch (e) {
      print('Prestataire non trouvé avec ID: $providerId');
      return null;
    }
  }

  List<ProviderModel> _getMockProvidersByService(String serviceId) {
    // Simuler des prestataires associés à un service spécifique
    switch (serviceId) {
      case '1': // Consultation médicale
        return _getMockProviders().where((p) => p.id == 'provider1' || p.id == 'provider4').toList();
      case '2': // Consultation dentaire
        return _getMockProviders().where((p) => p.id == 'provider2').toList();
      case '3': // Coiffeur - Coupe Homme
      case '6': // Coiffeur - Coupe Femme
        return _getMockProviders().where((p) => p.id == 'provider3').toList();
      case '4': // Consultation psychologique
        return _getMockProviders().where((p) => p.id == 'provider4').toList();
      case '5': // Massage thérapeutique
      case '8': // Massage relaxant
        return _getMockProviders().where((p) => p.id == 'provider5').toList();
      case '7': // Manucure
        return _getMockProviders().where((p) => p.id == 'provider6').toList();
      default:
        return [];
    }
  }

  List<ProviderModel> _getMockProviders() {
    return [
      ProviderModel(
        id: 'provider1',
        name: 'Dr. Martin Dupont',
        email: 'martin.dupont@example.com',
        phone: '+33123456789',
        photoUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
        specialties: ['Médecine générale', 'Pédiatrie'],
        rating: 4.8,
      ),
      ProviderModel(
        id: 'provider2',
        name: 'Dr. Sophie Laurent',
        email: 'sophie.laurent@example.com',
        phone: '+33123456790',
        photoUrl: 'https://randomuser.me/api/portraits/women/2.jpg',
        specialties: ['Dentisterie', 'Orthodontie'],
        rating: 4.9,
      ),
      ProviderModel(
        id: 'provider3',
        name: 'Jean Ciseaux',
        email: 'jean.ciseaux@example.com',
        phone: '+33123456791',
        photoUrl: 'https://randomuser.me/api/portraits/men/3.jpg',
        specialties: ['Coiffure homme', 'Coiffure femme', 'Coloration'],
        rating: 4.7,
      ),
      ProviderModel(
        id: 'provider4',
        name: 'Dr. Émilie Bernard',
        email: 'emilie.bernard@example.com',
        phone: '+33123456792',
        photoUrl: 'https://randomuser.me/api/portraits/women/4.jpg',
        specialties: ['Psychologie', 'Thérapie cognitive'],
        rating: 4.9,
      ),
      ProviderModel(
        id: 'provider5',
        name: 'Thomas Mains',
        email: 'thomas.mains@example.com',
        phone: '+33123456793',
        photoUrl: 'https://randomuser.me/api/portraits/men/5.jpg',
        specialties: ['Massage thérapeutique', 'Massage relaxant', 'Réflexologie'],
        rating: 4.8,
      ),
      ProviderModel(
        id: 'provider6',
        name: 'Julie Beauté',
        email: 'julie.beaute@example.com',
        phone: '+33123456794',
        photoUrl: 'https://randomuser.me/api/portraits/women/6.jpg',
        specialties: ['Manucure', 'Pédicure', 'Soins esthétiques'],
        rating: 4.6,
      ),
    ];
  }
}