// lib/services/booking_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createBooking({
    required String userId,
    required String providerId,
    required DateTime dateTime,
    required String service,
    required Map<String, dynamic> additionalInfo,
  }) async {
    await _firestore.collection('bookings').add({
      'userId': userId,
      'providerId': providerId,
      'dateTime': Timestamp.fromDate(dateTime),
      'service': service,
      'status': 'pending',
      'additionalInfo': additionalInfo,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': status,
    });
  }

  Stream<QuerySnapshot> getUserBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('dateTime', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getProviderBookings(String providerId) {
    return _firestore
        .collection('bookings')
        .where('providerId', isEqualTo: providerId)
        .orderBy('dateTime', descending: true)
        .snapshots();
  }
}