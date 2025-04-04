import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/category_model.dart';
import '../models/service_model.dart';
import '../models/appointment_model.dart';
import 'package:intl/intl.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Référence aux collections
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get categories => _firestore.collection('categories');
  CollectionReference get services => _firestore.collection('services');
  CollectionReference get appointments => _firestore.collection('bookings');
  CollectionReference get availability => _firestore.collection('availability');
  CollectionReference get reviews => _firestore.collection('reviews');
  CollectionReference get notifications => _firestore.collection('notifications');

  // Créer ou mettre à jour un document utilisateur
  Future<void> updateUserData(UserModel user) async {
    return await users.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  // Récupérer un utilisateur par ID
  Future<UserModel?> getUserById(String userId) async {
    DocumentSnapshot doc = await users.doc(userId).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  // Récupérer l'utilisateur actuel
  Future<UserModel?> getCurrentUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return await getUserById(user.uid);
    }
    return null;
  }

  // Récupérer tous les prestataires
  Future<List<UserModel>> getAllProviders() async {
    QuerySnapshot snapshot = await users
        .where('role', isEqualTo: 'UserRole.provider')
        .get();
    
    return snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();
  }

  // Récupérer toutes les catégories
  Future<List<CategoryModel>> getAllCategories() async {
    QuerySnapshot snapshot = await categories.orderBy('name').get();
    
    return snapshot.docs
        .map((doc) => CategoryModel.fromFirestore(doc))
        .toList();
  }

  // Récupérer tous les services d'une catégorie
  Future<List<ServiceModel>> getServicesByCategory(String categoryId) async {
    QuerySnapshot snapshot = await services
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('name')
        .get();
    
    return snapshot.docs
        .map((doc) => ServiceModel.fromFirestore(doc))
        .toList();
  }

  // Récupérer tous les services d'un prestataire
  Future<List<ServiceModel>> getServicesByProvider(String providerId) async {
    QuerySnapshot snapshot = await services
        .where('providerId', isEqualTo: providerId)
        .orderBy('name')
        .get();
    
    return snapshot.docs
        .map((doc) => ServiceModel.fromFirestore(doc))
        .toList();
  }

  // Rechercher des services par nom
  Future<List<ServiceModel>> searchServices(String query) async {
    // Convertir la requête en minuscules pour une recherche insensible à la casse
    String searchQuery = query.toLowerCase();
    
    QuerySnapshot snapshot = await services.get();
    
    // Filtrer les résultats côté client (Firestore ne supporte pas les recherches textuelles avancées)
    return snapshot.docs
        .map((doc) => ServiceModel.fromFirestore(doc))
        .where((service) => 
            service.name.toLowerCase().contains(searchQuery) ||
            service.description.toLowerCase().contains(searchQuery))
        .toList();
  }

  // Créer ou mettre à jour un rendez-vous
  Future<String> createAppointment(AppointmentModel appointment) async {
    DocumentReference docRef = await appointments.add(appointment.toMap());
    return docRef.id;
  }

  // Récupérer les rendez-vous d'un client
  Future<List<AppointmentModel>> getClientAppointments(String clientId) async {
    QuerySnapshot snapshot = await appointments
        .where('clientId', isEqualTo: clientId)
        .orderBy('dateTime', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => AppointmentModel.fromFirestore(doc))
        .toList();
  }

  // Récupérer les rendez-vous d'un prestataire
  Future<List<AppointmentModel>> getProviderAppointments(String providerId) async {
    QuerySnapshot snapshot = await appointments
        .where('providerId', isEqualTo: providerId)
        .orderBy('dateTime', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => AppointmentModel.fromFirestore(doc))
        .toList();
  }

  // Mettre à jour le statut d'un rendez-vous
  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    return await appointments.doc(appointmentId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Ajouter une disponibilité pour un prestataire
  Future<void> addAvailability(String providerId, DateTime startTime, DateTime endTime) async {
    await availability.add({
      'providerId': providerId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'isBooked': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Récupérer les disponibilités d'un prestataire
  Future<List<Map<String, dynamic>>> getProviderAvailability(String providerId) async {
    QuerySnapshot snapshot = await availability
        .where('providerId', isEqualTo: providerId)
        .where('isBooked', isEqualTo: false)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
        .orderBy('startTime')
        .get();
    
    return snapshot.docs
        .map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'startTime': (data['startTime'] as Timestamp).toDate(),
            'endTime': (data['endTime'] as Timestamp).toDate(),
          };
        })
        .toList();
  }

  // Ajouter un avis sur un service
  Future<void> addReview(String serviceId, String userId, String userName, double rating, String comment) async {
    await reviews.add({
      'serviceId': serviceId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Récupérer les avis d'un service
  Future<List<Map<String, dynamic>>> getServiceReviews(String serviceId) async {
    QuerySnapshot snapshot = await reviews
        .where('serviceId', isEqualTo: serviceId)
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'userId': data['userId'],
            'userName': data['userName'],
            'rating': data['rating'],
            'comment': data['comment'],
            'createdAt': (data['createdAt'] as Timestamp).toDate(),
          };
        })
        .toList();
  }

  // Peupler la base de données avec des données de test
  Future<void> populateTestData() async {
    print('Création des données de test...');
    
    // Créer des utilisateurs de test
    UserModel clientUser = UserModel(
      uid: 'client-test-id',
      email: 'client@test.com',
      fullName: 'Client Test',
      photoUrl: 'https://randomuser.me/api/portraits/women/1.jpg',
      role: UserRole.client,
      phoneNumber: '+33123456789',
    );
    
    UserModel providerUser = UserModel(
      uid: 'provider-test-id',
      email: 'provider@test.com',
      fullName: 'Prestataire Test',
      photoUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
      role: UserRole.provider,
      phoneNumber: '+33987654321',
    );
    
    // Créer un second prestataire
    UserModel providerUser2 = UserModel(
      uid: 'provider-test-id-2',
      email: 'provider2@test.com',
      fullName: 'Sophie Martin',
      photoUrl: 'https://randomuser.me/api/portraits/women/2.jpg',
      role: UserRole.provider,
      phoneNumber: '+33678901234',
    );
    
    await users.doc(clientUser.uid).set(clientUser.toMap());
    await users.doc(providerUser.uid).set(providerUser.toMap());
    await users.doc(providerUser2.uid).set(providerUser2.toMap());
    
    // Créer des catégories
    List<String> categoryIds = [];
    
    // 1. Catégorie Coiffure
    DocumentReference coiffureRef = await categories.add({
      'name': 'Coiffure',
      'description': 'Services de coiffure et soins capillaires',
      'iconName': 'cut',
      'imageUrl': 'https://images.unsplash.com/photo-1560066984-138dadb4c035',
      'serviceCount': 5, // Mise à jour du nombre de services
      'createdAt': FieldValue.serverTimestamp(),
    });
    categoryIds.add(coiffureRef.id);
    
    // 2. Catégorie Massage
    DocumentReference massageRef = await categories.add({
      'name': 'Massage',
      'description': 'Massages relaxants et thérapeutiques',
      'iconName': 'spa',
      'imageUrl': 'https://images.unsplash.com/photo-1544161515-4ab6ce6db874',
      'serviceCount': 4, // Mise à jour du nombre de services
      'createdAt': FieldValue.serverTimestamp(),
    });
    categoryIds.add(massageRef.id);
    
    // 3. Catégorie Esthétique
    DocumentReference esthetiqueRef = await categories.add({
      'name': 'Esthétique',
      'description': 'Soins esthétiques et beauté',
      'iconName': 'face',
      'imageUrl': 'https://images.unsplash.com/photo-1560750588-73207b1ef5b8',
      'serviceCount': 4, // Mise à jour du nombre de services
      'createdAt': FieldValue.serverTimestamp(),
    });
    categoryIds.add(esthetiqueRef.id);
    
    // 4. Nouvelle catégorie: Manucure & Pédicure
    DocumentReference manucureRef = await categories.add({
      'name': 'Manucure & Pédicure',
      'description': 'Soins des ongles et beauté des mains et pieds',
      'iconName': 'nail_polish',
      'imageUrl': 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b',
      'serviceCount': 3,
      'createdAt': FieldValue.serverTimestamp(),
    });
    categoryIds.add(manucureRef.id);
    
    // 5. Nouvelle catégorie: Maquillage
    DocumentReference maquillageRef = await categories.add({
      'name': 'Maquillage',
      'description': 'Services de maquillage professionnel pour toutes occasions',
      'iconName': 'face_retouching_natural',
      'imageUrl': 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9',
      'serviceCount': 3,
      'createdAt': FieldValue.serverTimestamp(),
    });
    categoryIds.add(maquillageRef.id);
    
    // 6. Nouvelle catégorie: Santé
    DocumentReference santeRef = await categories.add({
      'name': 'Santé',
      'description': 'Services de santé et bien-être',
      'iconName': 'medical_services',
      'imageUrl': 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528',
      'serviceCount': 4,
      'createdAt': FieldValue.serverTimestamp(),
    });
    categoryIds.add(santeRef.id);
    
    // Créer des services
    List<String> serviceIds = [];
    
    // Services de Coiffure
    DocumentReference coupeRef = await services.add({
      'name': 'Coupe et Brushing',
      'providerId': providerUser.uid,
      'categoryId': coiffureRef.id,
      'description': 'Coupe de cheveux professionnelle avec brushing',
      'durationMinutes': 60,
      'price': 45.0,
      'imageUrl': 'https://images.unsplash.com/photo-1562322140-8baeececf3df',
      'isPopular': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    serviceIds.add(coupeRef.id);
    
    DocumentReference colorationRef = await services.add({
      'name': 'Coloration',
      'providerId': providerUser.uid,
      'categoryId': coiffureRef.id,
      'description': 'Coloration professionnelle avec produits de qualité',
      'durationMinutes': 90,
      'price': 75.0,
      'imageUrl': 'https://images.unsplash.com/photo-1605497788044-5a32c7078486',
      'isPopular': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    serviceIds.add(colorationRef.id);
    
    await services.add({
      'name': 'Balayage',
      'providerId': providerUser2.uid,
      'categoryId': coiffureRef.id,
      'description': 'Technique de coloration pour un effet naturel et lumineux',
      'durationMinutes': 120,
      'price': 95.0,
      'imageUrl': 'https://images.unsplash.com/photo-1519699047748-de8e457a634e',
      'isPopular': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await services.add({
      'name': 'Coiffure de Mariage',
      'providerId': providerUser2.uid,
      'categoryId': coiffureRef.id,
      'description': 'Coiffure élégante pour votre jour spécial, avec essai inclus',
      'durationMinutes': 90,
      'price': 120.0,
      'imageUrl': 'https://images.unsplash.com/photo-1519699047748-de8e457a634e',
      'isPopular': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await services.add({
      'name': 'Soin Profond',
      'providerId': providerUser.uid,
      'categoryId': coiffureRef.id,
      'description': 'Traitement nourrissant pour cheveux abîmés',
      'durationMinutes': 45,
      'price': 55.0,
      'imageUrl': 'https://images.unsplash.com/photo-1527799820374-dcf8d9d4a388',
      'isPopular': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // Services de Massage
    DocumentReference massageRef2 = await services.add({
      'name': 'Massage Relaxant',
      'providerId': providerUser.uid,
      'categoryId': massageRef.id,
      'description': 'Massage relaxant pour soulager le stress et les tensions',
      'durationMinutes': 60,
      'price': 65.0,
      'imageUrl': 'https://images.unsplash.com/photo-1544161515-4ab6ce6db874',
      'isPopular': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    serviceIds.add(massageRef2.id);
    
    await services.add({
      'name': 'Massage Sportif',
      'providerId': providerUser.uid,
      'categoryId': massageRef.id,
      'description': 'Massage thérapeutique pour les sportifs, ciblant les zones de tension',
      'durationMinutes': 60,
      'price': 70.0,
      'imageUrl': 'https://images.unsplash.com/photo-1573879541250-58ae8b322b40',
      'isPopular': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await services.add({
      'name': 'Massage aux Pierres Chaudes',
      'providerId': providerUser2.uid,
      'categoryId': massageRef.id,
      'description': 'Massage relaxant avec pierres chaudes pour une détente profonde',
      'durationMinutes': 75,
      'price': 85.0,
      'imageUrl': 'https://images.unsplash.com/photo-1600334129128-685c5582fd35',
      'isPopular': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await services.add({
      'name': 'Réflexologie Plantaire',
      'providerId': providerUser2.uid,
      'categoryId': massageRef.id,
      'description': 'Massage des zones réflexes des pieds pour stimuler l\'énergie',
      'durationMinutes': 45,
      'price': 55.0,
      'imageUrl': 'https://images.unsplash.com/photo-1519823551278-64ac92734fb1',
      'isPopular': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // Services d'Esthétique
    await services.add({
      'name': 'Soin du Visage Hydratant',
      'providerId': providerUser2.uid,
      'categoryId': esthetiqueRef.id,
      'description': 'Soin complet pour hydrater et revitaliser la peau',
      'durationMinutes': 60,
      'price': 70.0,
      'imageUrl': 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881',
      'isPopular': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await services.add({
      'name': 'Épilation Visage',
      'providerId': providerUser2.uid,
      'categoryId': esthetiqueRef.id,
      'description': 'Épilation précise des sourcils, lèvre supérieure et menton',
      'durationMinutes': 30,
      'price': 35.0,
      'imageUrl': 'https://images.unsplash.com/photo-1560750588-73207b1ef5b8',
      'isPopular': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await services.add({
      'name': 'Épilation Jambes Complètes',
      'providerId': providerUser2.uid,
      'categoryId': esthetiqueRef.id,
      'description': 'Épilation à la cire des jambes complètes',
      'durationMinutes': 45,
      'price': 50.0,
      'imageUrl': 'https://images.unsplash.com/photo-1519415510236-58ae8b322b40',
      'isPopular': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await services.add({
      'name': 'Soin Anti-Âge',
      'providerId': providerUser.uid,
      'categoryId': esthetiqueRef.id,
      'description': 'Traitement intensif pour réduire les signes du vieillissement',
      'durationMinutes': 75,
      'price': 95.0,
      'imageUrl': 'https://images.unsplash.com/photo-1512290923902-0411a3b2b626',
      'isPopular': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // Services de Manucure & Pédicure
    await services.add({
      'name': 'Manucure Classique',
      'providerId': providerUser2.uid,
      'categoryId': manucureRef.id,
      'description': 'Soin des ongles, cuticules et pose de vernis classique',
      'durationMinutes': 45,
      'price': 35.0,
      'imageUrl': 'https://images.unsplash.com/photo-1604654894610-df63bc536371',
      'isPopular': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await services.add({
      'name': 'Pose de Gel',
      'providerId': providerUser2.uid,
      'categoryId': manucureRef.id,
      'description': 'Pose complète d\'ongles en gel avec design au choix',
      'durationMinutes': 75,
      'price': 65.0,
      'imageUrl': 'https://images.unsplash.com/photo-1604902396830-aca29e19b067',
      'isPopular': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await services.add({
      'name': 'Pédicure Spa',
      'providerId': providerUser.uid,
      'categoryId': manucureRef.id,
      'description': 'Soin complet des pieds avec bain, gommage et massage',
      'durationMinutes': 60,
      'price': 55.0,
      'imageUrl': 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b',
      'isPopular': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // Services de Maquillage
    await services.add({
      'name': 'Maquillage Jour',
      'providerId': providerUser2.uid,
      'categoryId': maquillageRef.id,
      'description': 'Maquillage léger et naturel pour la journée',
      'durationMinutes': 45,
      'price': 50.0,
      'imageUrl': 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9',
      'isPopular': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await services.add({
      'name': 'Maquillage Soirée',
      'providerId': providerUser2.uid,
      'categoryId': maquillageRef.id,
      'description': 'Maquillage sophistiqué pour les occasions spéciales',
      'durationMinutes': 60,
      'price': 70.0,
      'imageUrl': 'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2',
      'isPopular': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await services.add({
      'name': 'Maquillage Mariée',
      'providerId': providerUser.uid,
      'categoryId': maquillageRef.id,
      'description': 'Maquillage complet pour le jour de votre mariage, avec essai inclus',
      'durationMinutes': 90,
      'price': 120.0,
      'imageUrl': 'https://images.unsplash.com/photo-1457972729786-0411a3b2b626',
      'isPopular': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // Services de Santé
    await services.add({
      'name': 'Consultation Nutritionniste',
      'providerId': providerUser2.uid,
      'categoryId': santeRef.id,
      'description': 'Consultation personnalisée avec un nutritionniste pour des conseils alimentaires adaptés',
      'durationMinutes': 60,
      'price': 75.0,
      'imageUrl': 'https://images.unsplash.com/photo-1490645935967-10de6ba17061',
      'isPopular': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await services.add({
      'name': 'Séance d\'Ostéopathie',
      'providerId': providerUser.uid,
      'categoryId': santeRef.id,
      'description': 'Traitement manuel des dysfonctions de mobilité des tissus du corps',
      'durationMinutes': 45,
      'price': 80.0,
      'imageUrl': 'https://images.unsplash.com/photo-1573497620053-ea5300f94f21',
      'isPopular': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await services.add({
      'name': 'Consultation Psychologue',
      'providerId': providerUser2.uid,
      'categoryId': santeRef.id,
      'description': 'Séance d\'écoute et de soutien psychologique dans un cadre confidentiel',
      'durationMinutes': 50,
      'price': 85.0,
      'imageUrl': 'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e',
      'isPopular': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await services.add({
      'name': 'Coaching Sportif',
      'providerId': providerUser.uid,
      'categoryId': santeRef.id,
      'description': 'Séance personnalisée avec un coach sportif pour atteindre vos objectifs de forme',
      'durationMinutes': 60,
      'price': 65.0,
      'imageUrl': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b',
      'isPopular': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // Créer des disponibilités
    DateTime now = DateTime.now();
    DateTime today8am = DateTime(now.year, now.month, now.day, 8, 0);
    
    // Ajouter des disponibilités pour les 7 prochains jours
    for (int i = 0; i < 7; i++) {
      DateTime day = today8am.add(Duration(days: i));
      
      // Disponibilités de 9h à 17h avec des créneaux d'une heure
      for (int hour = 9; hour < 17; hour++) {
        DateTime startTime = DateTime(day.year, day.month, day.day, hour, 0);
        DateTime endTime = startTime.add(Duration(hours: 1));
        
        await availability.add({
          'providerId': providerUser.uid,
          'startTime': Timestamp.fromDate(startTime),
          'endTime': Timestamp.fromDate(endTime),
          'isBooked': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
    
    // Créer des rendez-vous
    DateTime tomorrow10am = DateTime(now.year, now.month, now.day + 1, 10, 0);
    DateTime nextWeek2pm = DateTime(now.year, now.month, now.day + 7, 14, 0);
    
    await appointments.add({
      'id': 'appointment-test-1',
      'clientId': clientUser.uid,
      'providerId': providerUser.uid,
      'serviceId': coupeRef.id,
      'serviceName': 'Coupe et Brushing',
      'dateTime': Timestamp.fromDate(tomorrow10am),
      'endTime': Timestamp.fromDate(tomorrow10am.add(Duration(minutes: 60))),
      'durationMinutes': 60,
      'price': 45.0,
      'status': 'confirmed',
      'notes': 'Première visite',
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await appointments.add({
      'id': 'appointment-test-2',
      'clientId': clientUser.uid,
      'providerId': providerUser.uid,
      'serviceId': massageRef2.id,
      'serviceName': 'Massage Relaxant',
      'dateTime': Timestamp.fromDate(nextWeek2pm),
      'endTime': Timestamp.fromDate(nextWeek2pm.add(Duration(minutes: 60))),
      'durationMinutes': 60,
      'price': 65.0,
      'status': 'pending',
      'notes': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // Ajouter des avis
    await reviews.add({
      'serviceId': coupeRef.id,
      'userId': clientUser.uid,
      'userName': clientUser.fullName,
      'rating': 4.5,
      'comment': 'Très satisfait de ma coupe, je recommande !',
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await reviews.add({
      'serviceId': massageRef2.id,
      'userId': clientUser.uid,
      'userName': clientUser.fullName,
      'rating': 5.0,
      'comment': 'Massage parfait, très relaxant et professionnel.',
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    print('Données de test créées avec succès !');
  }
}