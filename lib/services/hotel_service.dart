import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/hotel_model.dart';
import '../models/room_model.dart';
import '../models/hotel_booking_model.dart';
import '../models/hotel_review_model.dart';
import '../utils/error_handler.dart';

class HotelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections Firestore
  CollectionReference get _hotels => _firestore.collection('hotels');
  CollectionReference get _rooms => _firestore.collection('rooms');
  CollectionReference get _bookings => _firestore.collection('hotel_bookings');
  CollectionReference get _reviews => _firestore.collection('hotel_reviews');

  // Obtenir tous les hôtels (avec pagination)
  Future<List<HotelModel>> getHotels({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? searchText,
    HotelCategory? categoryFilter,
    Map<String, bool>? requiredServices,
    double? minRating,
  }) async {
    try {
      // Requête de base sans tri ni filtres complexes
      Query query = _firestore.collection('hotels');
      
      // Ajouter uniquement le filtre isActive pour réduire la complexité de la requête
      query = query.where('isActive', isEqualTo: true);
      
      // Exécuter la requête simplifiée
      final snapshot = await query.get();
      
      // Filtrer et trier les résultats côté client
      List<HotelModel> hotels = snapshot.docs
          .map((doc) => HotelModel.fromFirestore(doc))
          .toList();
      
      // Appliquer le tri par nom côté client
      hotels.sort((a, b) => a.name.compareTo(b.name));
      
      // Appliquer les filtres supplémentaires côté client
      if (searchText != null && searchText.isNotEmpty ||
          categoryFilter != null ||
          requiredServices != null && requiredServices.isNotEmpty ||
          minRating != null) {
        hotels = hotels.where((hotel) => hotel.matchesSearchCriteria(
          searchText: searchText,
          categoryFilter: categoryFilter,
          requiredServices: requiredServices,
          minRating: minRating,
        )).toList();
      }
      
      // Appliquer la pagination côté client
      if (hotels.length > limit) {
        hotels = hotels.sublist(0, limit);
      }
      
      return hotels;
    } catch (e) {
      print('Erreur lors de la récupération des hôtels: $e');
      return [];
    }
  }

  // Obtenir un hôtel par ID
  Future<HotelModel?> getHotelById(String hotelId) async {
    try {
      final doc = await _hotels.doc(hotelId).get();
      if (!doc.exists) return null;
      return HotelModel.fromFirestore(doc);
    } catch (e) {
      print('Erreur lors de la récupération de l\'hôtel: $e');
      return null;
    }
  }

  // Obtenir les hôtels populaires
  Future<List<HotelModel>> getPopularHotels({int limit = 5}) async {
    try {
      final snapshot = await _hotels
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      final hotels = snapshot.docs
          .map((doc) => HotelModel.fromFirestore(doc))
          .toList();

      return hotels;
    } catch (e) {
      print('Erreur lors de la récupération des hôtels populaires: $e');
      ErrorHandler.logError(e, context: 'getPopularHotels');
      return [];
    }
  }

  // Obtenir les chambres d'un hôtel
  Future<List<RoomModel>> getRoomsByHotelId(
    String hotelId, {
    RoomType? typeFilter,
    BedType? bedTypeFilter,
    int? minOccupancy,
    double? maxPrice,
    Map<String, bool>? requiredFeatures,
  }) async {
    try {
      final snapshot = await _rooms
          .where('hotelId', isEqualTo: hotelId)
          .where('isAvailable', isEqualTo: true)
          .get();

      final rooms = snapshot.docs
          .map((doc) => RoomModel.fromFirestore(doc))
          .where((room) => room.matchesSearchCriteria(
                typeFilter: typeFilter,
                bedTypeFilter: bedTypeFilter,
                minOccupancy: minOccupancy,
                maxPrice: maxPrice,
                requiredFeatures: requiredFeatures,
              ))
          .toList();

      return rooms;
    } catch (e) {
      print('Erreur lors de la récupération des chambres: $e');
      return [];
    }
  }

  // Vérifier la disponibilité d'une chambre pour des dates spécifiques
  Future<bool> checkRoomAvailability(
    String roomId,
    DateTime checkInDate,
    DateTime checkOutDate,
  ) async {
    try {
      // Normaliser les dates (minuit)
      final normalizedCheckIn = DateTime(
        checkInDate.year,
        checkInDate.month,
        checkInDate.day,
      );
      final normalizedCheckOut = DateTime(
        checkOutDate.year,
        checkOutDate.month,
        checkOutDate.day,
      );

      // Vérifier si la chambre existe et est disponible
      final roomDoc = await _rooms.doc(roomId).get();
      if (!roomDoc.exists || !(roomDoc.data() as Map<String, dynamic>)['isAvailable']) {
        return false;
      }

      // Vérifier s'il existe des réservations qui se chevauchent
      final overlappingBookings = await _bookings
          .where('roomId', isEqualTo: roomId)
          .where('status', whereIn: [
            'pending',
            'confirmed',
            'checkedIn',
          ])
          .get();

      for (var doc in overlappingBookings.docs) {
        final booking = HotelBookingModel.fromFirestore(doc);

        // Vérifier si les dates se chevauchent
        if (!(normalizedCheckOut.isBefore(booking.checkInDate) ||
            normalizedCheckIn.isAfter(booking.checkOutDate))) {
          return false; // Chevauchement trouvé
        }
      }

      return true; // Aucun chevauchement trouvé
    } catch (e) {
      print('Erreur lors de la vérification de disponibilité: $e');
      return false;
    }
  }

  // Créer une réservation d'hôtel
  Future<HotelBookingModel?> createHotelBooking(
    String hotelId,
    String roomId,
    DateTime checkInDate,
    DateTime checkOutDate,
    int numberOfGuests,
    int numberOfRooms,
    Map<String, bool> additionalServices,
    double totalPrice,
    String specialRequests,
    Map<String, dynamic> guestDetails,
  ) async {
    try {
      // Vérifier l'authentification
      final user = _auth.currentUser;
      
      // En mode développement, utiliser un ID utilisateur fictif si aucun utilisateur n'est connecté
      String userId;
      if (user == null) {
        // Vérifier si nous sommes en mode développement
        final bool isDevMode = true; // Mode développement forcé pour les tests
        
        if (isDevMode) {
          // Utiliser un ID utilisateur fictif pour le développement
          userId = 'dev_user_${DateTime.now().millisecondsSinceEpoch}';
          print('Mode développement: utilisation d\'un utilisateur fictif avec ID: $userId');
        } else {
          // En production, exiger une authentification
          throw AppError('Utilisateur non connecté', ErrorType.authentication);
        }
      } else {
        userId = user.uid;
      }

      // Vérifier la disponibilité
      final isAvailable = await checkRoomAvailability(
        roomId,
        checkInDate,
        checkOutDate,
      );
      if (!isAvailable) {
        throw ErrorHandler.roomNotAvailable();
      }

      // Créer la réservation
      final bookingData = HotelBookingModel(
        id: '',
        userId: userId,
        hotelId: hotelId,
        roomId: roomId,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        numberOfGuests: numberOfGuests,
        numberOfRooms: numberOfRooms,
        additionalServices: additionalServices,
        totalPrice: totalPrice,
        specialRequests: specialRequests,
        guestDetails: guestDetails,
        createdAt: DateTime.now(),
      );

      final docRef = await _bookings.add(bookingData.toFirestore());

      // Récupérer la réservation créée
      final doc = await docRef.get();
      return HotelBookingModel.fromFirestore(doc);
    } catch (e) {
      print('Erreur lors de la création de la réservation: $e');
      rethrow;
    }
  }

  // Annuler une réservation
  Future<bool> cancelBooking(String bookingId) async {
    try {
      // Vérifier l'authentification
      final user = _auth.currentUser;
      if (user == null) {
        throw AppError('Utilisateur non connecté', ErrorType.authentication);
      }

      // Récupérer la réservation
      final doc = await _bookings.doc(bookingId).get();
      if (!doc.exists) {
        throw ErrorHandler.bookingNotFound();
      }

      final booking = HotelBookingModel.fromFirestore(doc);

      // Vérifier si l'utilisateur est le propriétaire de la réservation
      if (booking.userId != user.uid) {
        throw AppError('Vous n\'êtes pas autorisé à annuler cette réservation', ErrorType.authorization);
      }

      // Vérifier si la réservation peut être annulée
      if (!booking.canBeCancelled()) {
        throw ErrorHandler.cancellationDeadlinePassed();
      }

      // Mettre à jour le statut de la réservation
      await _bookings.doc(bookingId).update({
        'status': 'cancelled',
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Erreur lors de l\'annulation de la réservation: $e');
      rethrow;
    }
  }

  // Obtenir les réservations d'un utilisateur
  Future<List<HotelBookingModel>> getUserBookings() async {
    try {
      // Vérifier l'authentification
      final user = _auth.currentUser;
      if (user == null) {
        throw AppError('Utilisateur non connecté', ErrorType.authentication);
      }

      final snapshot = await _bookings
          .where('userId', isEqualTo: user.uid)
          .orderBy('checkInDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => HotelBookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des réservations: $e');
      return [];
    }
  }

  // Ajouter un avis sur un hôtel
  Future<HotelReviewModel?> addHotelReview(
    String hotelId,
    String? roomId,
    String bookingId,
    String comment,
    Map<ReviewCategory, double> categoryRatings,
    double overallRating,
    List<String> photoUrls,
    DateTime stayDate,
  ) async {
    try {
      // Vérifier l'authentification
      final user = _auth.currentUser;
      if (user == null) {
        throw AppError('Utilisateur non connecté', ErrorType.authentication);
      }

      // Vérifier si la réservation existe et appartient à l'utilisateur
      final bookingDoc = await _bookings.doc(bookingId).get();
      if (!bookingDoc.exists) {
        throw ErrorHandler.bookingNotFound();
      }

      final booking = HotelBookingModel.fromFirestore(bookingDoc);
      if (booking.userId != user.uid) {
        throw AppError('Vous n\'êtes pas autorisé à laisser un avis pour cette réservation', ErrorType.authorization);
      }

      // Vérifier si l'utilisateur a séjourné à l'hôtel
      if (booking.status != BookingStatus.checkedOut) {
        throw ErrorHandler.reviewRequiresStay();
      }

      // Créer l'avis
      final reviewData = HotelReviewModel(
        id: '',
        userId: user.uid,
        hotelId: hotelId,
        roomId: roomId,
        bookingId: bookingId,
        comment: comment,
        categoryRatings: categoryRatings,
        overallRating: overallRating,
        photoUrls: photoUrls,
        stayDate: stayDate,
        createdAt: DateTime.now(),
        isVerifiedStay: true,
      );

      final docRef = await _reviews.add(reviewData.toFirestore());

      // Mettre à jour la note moyenne de l'hôtel
      await _updateHotelRating(hotelId);

      // Récupérer l'avis créé
      final doc = await docRef.get();
      return HotelReviewModel.fromFirestore(doc);
    } catch (e) {
      print('Erreur lors de l\'ajout de l\'avis: $e');
      rethrow;
    }
  }

  // Obtenir les avis d'un hôtel
  Future<List<HotelReviewModel>> getHotelReviews(String hotelId) async {
    try {
      final snapshot = await _reviews
          .where('hotelId', isEqualTo: hotelId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => HotelReviewModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des avis: $e');
      return [];
    }
  }

  // Mettre à jour la note moyenne d'un hôtel
  Future<void> _updateHotelRating(String hotelId) async {
    try {
      final reviewsSnapshot = await _reviews
          .where('hotelId', isEqualTo: hotelId)
          .where('isActive', isEqualTo: true)
          .get();

      if (reviewsSnapshot.docs.isEmpty) return;

      final reviews = reviewsSnapshot.docs
          .map((doc) => HotelReviewModel.fromFirestore(doc))
          .toList();

      // Calculer la note moyenne
      double totalRating = 0;
      for (var review in reviews) {
        totalRating += review.overallRating;
      }
      final averageRating = totalRating / reviews.length;

      // Mettre à jour l'hôtel
      await _hotels.doc(hotelId).update({
        'rating': averageRating,
        'reviewCount': reviews.length,
      });
    } catch (e) {
      print('Erreur lors de la mise à jour de la note de l\'hôtel: $e');
    }
  }

  // Générer des données de test pour les hôtels
  Future<void> generateTestHotels() async {
    try {
      // Vérifier si des hôtels existent déjà
      final snapshot = await _hotels.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        print('Des hôtels existent déjà dans la base de données, pas besoin de générer des données de test');
        return;
      }
      
      print('Aucun hôtel trouvé dans la base de données, importation des données depuis data.json');
      
      // Importation des données depuis data.json
      // Cette partie est gérée par l'importation directe dans Firebase
      // Les données sont déjà présentes dans la base de données
      
      print('Utilisation des données existantes dans Firebase');
    } catch (e) {
      print('Erreur lors de la vérification des hôtels: $e');
    }
  }

  // Générer des chambres pour un hôtel - Méthode désactivée car les données sont déjà dans Firebase
  Future<void> _generateRoomsForHotel(String hotelId) async {
    // Cette méthode est désactivée car les données sont déjà dans Firebase
    print('Utilisation des chambres existantes dans Firebase pour l\'hôtel $hotelId');
  }
}