import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum RestaurantBookingStatus {
  pending,
  confirmed,
  cancelled,
  completed,
  noShow
}

class RestaurantBookingModel {
  final String id;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final DateTime date; 
  final String time; 
  final int guestCount;
  final String specialRequests;
  final RestaurantBookingStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? tableId;
  final String? phoneNumber;
  final String? email;
  final String? customerName;

  RestaurantBookingModel({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    required this.date,
    required this.time,
    required this.guestCount,
    this.specialRequests = '',
    this.status = RestaurantBookingStatus.pending,
    required this.createdAt,
    this.updatedAt,
    this.tableId,
    this.phoneNumber,
    this.email,
    this.customerName,
  });

  factory RestaurantBookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RestaurantBookingModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] ?? '',
      guestCount: data['guestCount'] ?? 1,
      specialRequests: data['specialRequests'] ?? '',
      status: _bookingStatusFromString(data['status'] ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      tableId: data['tableId'],
      phoneNumber: data['phoneNumber'],
      email: data['email'],
      customerName: data['customerName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'date': Timestamp.fromDate(date),
      'time': time,
      'guestCount': guestCount,
      'specialRequests': specialRequests,
      'status': _bookingStatusToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'tableId': tableId,
      'phoneNumber': phoneNumber,
      'email': email,
      'customerName': customerName,
    };
  }

  static RestaurantBookingStatus _bookingStatusFromString(String status) {
    switch (status) {
      case 'confirmed':
        return RestaurantBookingStatus.confirmed;
      case 'cancelled':
        return RestaurantBookingStatus.cancelled;
      case 'completed':
        return RestaurantBookingStatus.completed;
      case 'noShow':
        return RestaurantBookingStatus.noShow;
      case 'pending':
      default:
        return RestaurantBookingStatus.pending;
    }
  }

  static String _bookingStatusToString(RestaurantBookingStatus status) {
    switch (status) {
      case RestaurantBookingStatus.confirmed:
        return 'confirmed';
      case RestaurantBookingStatus.cancelled:
        return 'cancelled';
      case RestaurantBookingStatus.completed:
        return 'completed';
      case RestaurantBookingStatus.noShow:
        return 'noShow';
      case RestaurantBookingStatus.pending:
      default:
        return 'pending';
    }
  }

  String getStatusName() {
    switch (status) {
      case RestaurantBookingStatus.confirmed:
        return 'Réservation confirmée';
      case RestaurantBookingStatus.cancelled:
        return 'Réservation annulée';
      case RestaurantBookingStatus.completed:
        return 'Visite effectuée';
      case RestaurantBookingStatus.noShow:
        return 'Non présenté';
      case RestaurantBookingStatus.pending:
      default:
        return 'Réservation en attente';
    }
  }

  Color getStatusColor() {
    switch (status) {
      case RestaurantBookingStatus.confirmed:
        return Colors.green;
      case RestaurantBookingStatus.cancelled:
        return Colors.red;
      case RestaurantBookingStatus.completed:
        return Colors.blue;
      case RestaurantBookingStatus.noShow:
        return Colors.orange;
      case RestaurantBookingStatus.pending:
      default:
        return Colors.amber;
    }
  }

  bool canBeCancelled() {
    return status == RestaurantBookingStatus.pending || 
           status == RestaurantBookingStatus.confirmed;
  }

  bool isUpcoming() {
    final now = DateTime.now();
    return date.isAfter(now) && 
           (status == RestaurantBookingStatus.pending || 
            status == RestaurantBookingStatus.confirmed);
  }

  RestaurantBookingModel copyWith({
    String? id,
    String? userId,
    String? restaurantId,
    String? restaurantName,
    DateTime? date,
    String? time,
    int? guestCount,
    String? specialRequests,
    RestaurantBookingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? tableId,
    String? phoneNumber,
    String? email,
    String? customerName,
  }) {
    return RestaurantBookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      date: date ?? this.date,
      time: time ?? this.time,
      guestCount: guestCount ?? this.guestCount,
      specialRequests: specialRequests ?? this.specialRequests,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tableId: tableId ?? this.tableId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      customerName: customerName ?? this.customerName,
    );
  }
}