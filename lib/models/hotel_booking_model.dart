import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  pending,
  confirmed,
  checkedIn,
  checkedOut,
  cancelled,
  noShow
}

enum PaymentStatus {
  pending,
  paid,
  partiallyPaid,
  refunded,
  failed
}

class HotelBookingModel {
  final String id;
  final String userId;
  final String hotelId;
  final String roomId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int numberOfGuests;
  final int numberOfRooms;
  final Map<String, bool> additionalServices;
  final double totalPrice;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final String specialRequests;
  final Map<String, dynamic> guestDetails;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;

  HotelBookingModel({
    required this.id,
    required this.userId,
    required this.hotelId,
    required this.roomId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.numberOfGuests,
    this.numberOfRooms = 1,
    required this.additionalServices,
    required this.totalPrice,
    this.status = BookingStatus.pending,
    this.paymentStatus = PaymentStatus.pending,
    this.specialRequests = '',
    required this.guestDetails,
    required this.createdAt,
    this.updatedAt,
    this.metadata = const {},
  });

  // Getters pour les services additionnels
  bool get includesBreakfast => additionalServices['breakfast'] ?? false;
  bool get includesSpa => additionalServices['spa'] ?? false;
  bool get includesAirportTransfer => additionalServices['airportTransfer'] ?? false;

  // Getter pour la durée du séjour en jours
  int get stayDuration {
    return checkOutDate.difference(checkInDate).inDays;
  }

  // Conversion depuis/vers Firestore
  factory HotelBookingModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return HotelBookingModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      hotelId: data['hotelId'] ?? '',
      roomId: data['roomId'] ?? '',
      checkInDate: (data['checkInDate'] as Timestamp).toDate(),
      checkOutDate: (data['checkOutDate'] as Timestamp).toDate(),
      numberOfGuests: data['numberOfGuests'] ?? 1,
      numberOfRooms: data['numberOfRooms'] ?? 1,
      additionalServices: Map<String, bool>.from(data['additionalServices'] ?? {}),
      totalPrice: (data['totalPrice'] ?? 0.0).toDouble(),
      status: _bookingStatusFromString(data['status'] ?? 'pending'),
      paymentStatus: _paymentStatusFromString(data['paymentStatus'] ?? 'pending'),
      specialRequests: data['specialRequests'] ?? '',
      guestDetails: data['guestDetails'] ?? {},
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'hotelId': hotelId,
      'roomId': roomId,
      'checkInDate': Timestamp.fromDate(checkInDate),
      'checkOutDate': Timestamp.fromDate(checkOutDate),
      'numberOfGuests': numberOfGuests,
      'numberOfRooms': numberOfRooms,
      'additionalServices': additionalServices,
      'totalPrice': totalPrice,
      'status': _bookingStatusToString(status),
      'paymentStatus': _paymentStatusToString(paymentStatus),
      'specialRequests': specialRequests,
      'guestDetails': guestDetails,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'metadata': metadata,
    };
  }

  // Helpers pour la conversion des enums
  static BookingStatus _bookingStatusFromString(String status) {
    switch (status) {
      case 'pending': return BookingStatus.pending;
      case 'confirmed': return BookingStatus.confirmed;
      case 'checkedIn': return BookingStatus.checkedIn;
      case 'checkedOut': return BookingStatus.checkedOut;
      case 'cancelled': return BookingStatus.cancelled;
      case 'noShow': return BookingStatus.noShow;
      default: return BookingStatus.pending;
    }
  }

  static String _bookingStatusToString(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending: return 'pending';
      case BookingStatus.confirmed: return 'confirmed';
      case BookingStatus.checkedIn: return 'checkedIn';
      case BookingStatus.checkedOut: return 'checkedOut';
      case BookingStatus.cancelled: return 'cancelled';
      case BookingStatus.noShow: return 'noShow';
    }
  }

  static PaymentStatus _paymentStatusFromString(String status) {
    switch (status) {
      case 'pending': return PaymentStatus.pending;
      case 'paid': return PaymentStatus.paid;
      case 'partiallyPaid': return PaymentStatus.partiallyPaid;
      case 'refunded': return PaymentStatus.refunded;
      case 'failed': return PaymentStatus.failed;
      default: return PaymentStatus.pending;
    }
  }

  static String _paymentStatusToString(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending: return 'pending';
      case PaymentStatus.paid: return 'paid';
      case PaymentStatus.partiallyPaid: return 'partiallyPaid';
      case PaymentStatus.refunded: return 'refunded';
      case PaymentStatus.failed: return 'failed';
    }
  }

  // Obtenir le nom français du statut de réservation
  String getStatusName() {
    switch (status) {
      case BookingStatus.pending: return 'En attente';
      case BookingStatus.confirmed: return 'Confirmée';
      case BookingStatus.checkedIn: return 'Enregistré';
      case BookingStatus.checkedOut: return 'Terminée';
      case BookingStatus.cancelled: return 'Annulée';
      case BookingStatus.noShow: return 'Non présenté';
    }
  }

  // Obtenir le nom français du statut de paiement
  String getPaymentStatusName() {
    switch (paymentStatus) {
      case PaymentStatus.pending: return 'En attente';
      case PaymentStatus.paid: return 'Payé';
      case PaymentStatus.partiallyPaid: return 'Partiellement payé';
      case PaymentStatus.refunded: return 'Remboursé';
      case PaymentStatus.failed: return 'Échec';
    }
  }

  // Vérifier si la réservation peut être annulée (24h avant l'arrivée)
  bool canBeCancelled() {
    final now = DateTime.now();
    final cancellationDeadline = checkInDate.subtract(Duration(hours: 24));
    return now.isBefore(cancellationDeadline) && 
           status != BookingStatus.cancelled && 
           status != BookingStatus.checkedIn &&
           status != BookingStatus.checkedOut &&
           status != BookingStatus.noShow;
  }

  // Vérifier si la réservation peut être modifiée (48h avant l'arrivée)
  bool canBeModified() {
    final now = DateTime.now();
    final modificationDeadline = checkInDate.subtract(Duration(hours: 48));
    return now.isBefore(modificationDeadline) && 
           status != BookingStatus.cancelled && 
           status != BookingStatus.checkedIn &&
           status != BookingStatus.checkedOut &&
           status != BookingStatus.noShow;
  }
}