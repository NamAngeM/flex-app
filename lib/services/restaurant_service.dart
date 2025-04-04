import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';
import '../models/restaurant_table_model.dart';
import '../models/restaurant_booking_model.dart';
import '../models/menu_item_model.dart';
import '../models/restaurant_order_model.dart';
import '../utils/error_handler.dart';

class RestaurantService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections Firestore
  CollectionReference get _restaurants => _firestore.collection('restaurants');
  CollectionReference get _tables => _firestore.collection('restaurant_tables');
  CollectionReference get _bookings => _firestore.collection('restaurant_bookings');
  CollectionReference get _menuItems => _firestore.collection('menu_items');
  CollectionReference get _orders => _firestore.collection('restaurant_orders');

  // Obtenir tous les restaurants (avec pagination)
  Future<List<RestaurantModel>> getRestaurants({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? searchText,
    RestaurantCategory? categoryFilter,
    List<String>? cuisineFilters,
    Map<String, bool>? requiredFeatures,
    double? minRating,
    bool? mustAcceptReservations,
    bool? mustAcceptOnlineOrders,
  }) async {
    try {
      Query query = _restaurants
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final restaurants = snapshot.docs
          .map((doc) => RestaurantModel.fromFirestore(doc))
          .where((restaurant) => restaurant.matchesSearchCriteria(
                searchText: searchText,
                categoryFilter: categoryFilter,
                cuisineFilters: cuisineFilters,
                requiredFeatures: requiredFeatures,
                minRating: minRating,
                mustAcceptReservations: mustAcceptReservations,
                mustAcceptOnlineOrders: mustAcceptOnlineOrders,
              ))
          .toList();

      return restaurants;
    } catch (e) {
      print('Erreur lors de la récupération des restaurants: $e');
      return [];
    }
  }

  // Obtenir un restaurant par ID
  Future<RestaurantModel?> getRestaurantById(String restaurantId) async {
    try {
      final doc = await _restaurants.doc(restaurantId).get();
      if (!doc.exists) return null;
      return RestaurantModel.fromFirestore(doc);
    } catch (e) {
      print('Erreur lors de la récupération du restaurant: $e');
      return null;
    }
  }

  // Obtenir les tables d'un restaurant
  Future<List<RestaurantTableModel>> getTablesByRestaurantId(String restaurantId) async {
    try {
      final snapshot = await _tables
          .where('restaurantId', isEqualTo: restaurantId)
          .where('isAvailable', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => RestaurantTableModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des tables: $e');
      return [];
    }
  }

  // Vérifier la disponibilité d'une table pour une date et heure spécifiques
  Future<bool> checkTableAvailability(
    String restaurantId,
    String? tableId,
    DateTime date,
    String time,
    int numberOfGuests,
  ) async {
    try {
      // Si aucune table spécifique n'est demandée, vérifier s'il y a des tables disponibles
      if (tableId == null) {
        final availableTables = await _getAvailableTables(
          restaurantId,
          date,
          time,
          numberOfGuests,
        );
        return availableTables.isNotEmpty;
      }

      // Vérifier si la table spécifique est disponible
      final bookings = await _getBookingsForDate(restaurantId, date);
      
      // Convertir l'heure en minutes pour faciliter la comparaison
      final requestedTimeMinutes = _timeToMinutes(time);
      
      // Vérifier si la table est déjà réservée à cette heure
      for (final booking in bookings) {
        // Ignorer les réservations annulées
        if (booking.status == RestaurantBookingStatus.cancelled) {
          continue;
        }
        
        // Ignorer les réservations pour d'autres tables
        if (booking.tableId != tableId) {
          continue;
        }
        
        final bookingTimeMinutes = _timeToMinutes(booking.time);
        
        // Vérifier si les créneaux horaires se chevauchent
        // On considère qu'une réservation dure 2 heures (120 minutes)
        if ((requestedTimeMinutes >= bookingTimeMinutes && 
             requestedTimeMinutes < bookingTimeMinutes + 120) ||
            (bookingTimeMinutes >= requestedTimeMinutes && 
             bookingTimeMinutes < requestedTimeMinutes + 120)) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      print('Erreur lors de la vérification de la disponibilité: $e');
      return false;
    }
  }

  // Obtenir les tables disponibles pour une date et heure spécifiques
  Future<List<RestaurantTableModel>> getAvailableTables({
    required String restaurantId,
    required DateTime date,
    required String time,
    required int guestCount,
  }) async {
    return _getAvailableTables(
      restaurantId,
      date,
      time,
      guestCount,
    );
  }

  // Méthode privée pour obtenir les tables disponibles
  Future<List<RestaurantTableModel>> _getAvailableTables(
    String restaurantId,
    DateTime date,
    String time,
    int numberOfGuests,
  ) async {
    try {
      // Récupérer toutes les tables du restaurant avec une capacité suffisante
      final tablesSnapshot = await _tables
          .where('restaurantId', isEqualTo: restaurantId)
          .where('isAvailable', isEqualTo: true)
          .where('capacity', isGreaterThanOrEqualTo: numberOfGuests)
          .get();

      final tables = tablesSnapshot.docs
          .map((doc) => RestaurantTableModel.fromFirestore(doc))
          .toList();

      // Récupérer toutes les réservations pour cette date
      final bookings = await _getBookingsForDate(restaurantId, date);

      // Filtrer les tables qui sont déjà réservées à l'heure demandée
      final requestedTimeMinutes = _timeToMinutes(time);
      
      // On considère qu'une réservation dure 2 heures (120 minutes)
      return tables.where((table) {
        // Vérifier si la table est déjà réservée à l'heure demandée
        for (final booking in bookings) {
          // Ignorer les réservations annulées
          if (booking.status == RestaurantBookingStatus.cancelled) {
            continue;
          }
          
          // Ignorer les réservations pour d'autres tables
          if (booking.tableId != table.id) {
            continue;
          }
          
          final bookingTimeMinutes = _timeToMinutes(booking.time);
          
          // Vérifier si les créneaux horaires se chevauchent
          if ((requestedTimeMinutes >= bookingTimeMinutes && 
               requestedTimeMinutes < bookingTimeMinutes + 120) ||
              (bookingTimeMinutes >= requestedTimeMinutes && 
               bookingTimeMinutes < requestedTimeMinutes + 120)) {
            return false; // Table non disponible à cette heure
          }
        }
        return true; // Table disponible
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des tables disponibles: $e');
      return [];
    }
  }

  // Récupérer les réservations pour une date spécifique
  Future<List<RestaurantBookingModel>> _getBookingsForDate(String restaurantId, DateTime date) async {
    try {
      final snapshot = await _bookings
          .where('restaurantId', isEqualTo: restaurantId)
          .where('date', isEqualTo: Timestamp.fromDate(DateTime(date.year, date.month, date.day)))
          .get();

      return snapshot.docs
          .map((doc) => RestaurantBookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des réservations: $e');
      return [];
    }
  }

  // Convertir une heure au format "HH:MM" en minutes depuis minuit
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
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
        throw AppError('Réservation non trouvée', ErrorType.booking);
      }

      final booking = RestaurantBookingModel.fromFirestore(doc);
      
      // Vérifier si l'utilisateur est le propriétaire de la réservation
      if (booking.userId != user.uid) {
        throw AppError('Vous n\'êtes pas autorisé à annuler cette réservation', ErrorType.authorization);
      }

      // Vérifier si la réservation peut être annulée
      if (!booking.canBeCancelled()) {
        throw AppError('Le délai d\'annulation est dépassé', ErrorType.validation);
      }

      // Annuler la réservation
      await _bookings.doc(bookingId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Erreur lors de l\'annulation de la réservation: $e');
      rethrow;
    }
  }

  // Obtenir les réservations d'un utilisateur
  Future<List<RestaurantBookingModel>> getUserBookings() async {
    try {
      // Vérifier l'authentification
      final user = _auth.currentUser;
      if (user == null) {
        throw AppError('Utilisateur non connecté', ErrorType.authentication);
      }

      final snapshot = await _bookings
          .where('userId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RestaurantBookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des réservations: $e');
      return [];
    }
  }

  // Obtenir les éléments du menu d'un restaurant
  Future<List<MenuItemModel>> getMenuItems(String restaurantId) async {
    try {
      final snapshot = await _menuItems
          .where('restaurantId', isEqualTo: restaurantId)
          .where('isAvailable', isEqualTo: true)
          .orderBy('category')
          .get();

      return snapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc, doc.id))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des éléments du menu: $e');
      return [];
    }
  }

  // Créer une nouvelle réservation
  Future<RestaurantBookingModel> createBooking(RestaurantBookingModel booking) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AppError('Utilisateur non connecté', ErrorType.authentication);
      }

      // Vérifier la disponibilité
      final isAvailable = await checkTableAvailability(
        booking.restaurantId,
        booking.tableId,
        booking.date,
        booking.time,
        booking.guestCount,
      );

      if (!isAvailable) {
        throw AppError('Aucune table disponible pour cette date et ce créneau horaire', ErrorType.validation);
      }

      // Créer la réservation
      final bookingData = booking.toFirestore();
      final docRef = await _bookings.add(bookingData);
      
      // Récupérer la réservation créée
      final doc = await docRef.get();
      return RestaurantBookingModel.fromFirestore(doc);
    } catch (e) {
      print('Erreur lors de la création de la réservation: $e');
      rethrow;
    }
  }

  // Créer une commande
  Future<RestaurantOrderModel?> createOrder(
    String restaurantId,
    List<OrderItem> items,
    OrderType type,
    DateTime? pickupTime,
    String? deliveryAddress,
    double subtotal,
    double taxAmount,
    double deliveryFee,
    double discount,
    double totalAmount,
    String paymentMethod,
  ) async {
    try {
      // Vérifier l'authentification
      final user = _auth.currentUser;
      if (user == null) {
        throw AppError('Utilisateur non connecté', ErrorType.authentication);
      }

      // Créer la commande
      final orderData = RestaurantOrderModel(
        id: '',
        userId: user.uid,
        restaurantId: restaurantId,
        items: items,
        type: type,
        orderTime: DateTime.now(),
        pickupTime: pickupTime,
        deliveryAddress: deliveryAddress,
        subtotal: subtotal,
        taxAmount: taxAmount,
        deliveryFee: deliveryFee,
        discount: discount,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
        createdAt: DateTime.now(),
      );

      final docRef = await _orders.add(orderData.toFirestore());
      
      // Récupérer la commande créée
      final doc = await docRef.get();
      return RestaurantOrderModel.fromFirestore(doc);
    } catch (e) {
      print('Erreur lors de la création de la commande: $e');
      rethrow;
    }
  }

  // Annuler une commande
  Future<bool> cancelOrder(String orderId) async {
    try {
      // Vérifier l'authentification
      final user = _auth.currentUser;
      if (user == null) {
        throw AppError('Utilisateur non connecté', ErrorType.authentication);
      }

      // Récupérer la commande
      final doc = await _orders.doc(orderId).get();
      if (!doc.exists) {
        throw AppError('Commande non trouvée', ErrorType.order);
      }

      final order = RestaurantOrderModel.fromFirestore(doc);
      
      // Vérifier si l'utilisateur est le propriétaire de la commande
      if (order.userId != user.uid) {
        throw AppError('Vous n\'êtes pas autorisé à annuler cette commande', ErrorType.authorization);
      }

      // Vérifier si la commande peut être annulée
      if (!order.canBeCancelled()) {
        throw AppError('Le délai d\'annulation est dépassé', ErrorType.validation);
      }

      // Annuler la commande
      await _orders.doc(orderId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Erreur lors de l\'annulation de la commande: $e');
      rethrow;
    }
  }

  // Obtenir les commandes d'un utilisateur
  Future<List<RestaurantOrderModel>> getUserOrders() async {
    try {
      // Vérifier l'authentification
      final user = _auth.currentUser;
      if (user == null) {
        throw AppError('Utilisateur non connecté', ErrorType.authentication);
      }

      final snapshot = await _orders
          .where('userId', isEqualTo: user.uid)
          .orderBy('orderTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RestaurantOrderModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des commandes: $e');
      return [];
    }
  }
}