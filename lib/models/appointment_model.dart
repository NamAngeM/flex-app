import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus {
  pending,
  confirmed,
  cancelled,
  completed,
  noShow
}

class AppointmentModel {
  final String id;
  final String clientId;
  final String providerId;
  final String serviceId;
  final DateTime dateTime;
  final int durationMinutes;
  final AppointmentStatus status;
  final String? notes;
  final DateTime createdAt;

  AppointmentModel({
    required this.id,
    required this.clientId,
    required this.providerId,
    required this.serviceId,
    required this.dateTime,
    required this.durationMinutes,
    required this.status,
    this.notes,
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Convertir le statut de string à enum
    AppointmentStatus getStatus(String? statusStr) {
      switch (statusStr?.toLowerCase()) {
        case 'confirmed':
          return AppointmentStatus.confirmed;
        case 'cancelled':
          return AppointmentStatus.cancelled;
        case 'completed':
          return AppointmentStatus.completed;
        case 'noshow':
        case 'no_show':
          return AppointmentStatus.noShow;
        case 'pending':
        default:
          return AppointmentStatus.pending;
      }
    }
    
    return AppointmentModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      providerId: data['providerId'] ?? '',
      serviceId: data['serviceId'] ?? '',
      dateTime: (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationMinutes: data['durationMinutes'] ?? 60,
      status: getStatus(data['status']),
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    // Convertir le statut de enum à string
    String getStatusString(AppointmentStatus status) {
      switch (status) {
        case AppointmentStatus.confirmed:
          return 'confirmed';
        case AppointmentStatus.cancelled:
          return 'cancelled';
        case AppointmentStatus.completed:
          return 'completed';
        case AppointmentStatus.noShow:
          return 'noShow';
        case AppointmentStatus.pending:
        default:
          return 'pending';
      }
    }
    
    return {
      'clientId': clientId,
      'providerId': providerId,
      'serviceId': serviceId,
      'dateTime': Timestamp.fromDate(dateTime),
      'durationMinutes': durationMinutes,
      'status': getStatusString(status),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Vérifier si le rendez-vous est à venir
  bool get isUpcoming => dateTime.isAfter(DateTime.now());
  
  // Vérifier si le rendez-vous est annulable (à venir et non annulé)
  bool get isCancellable => isUpcoming && status != AppointmentStatus.cancelled;
  
  // Obtenir la date de fin du rendez-vous
  DateTime get endTime => dateTime.add(Duration(minutes: durationMinutes));
  
  // Créer une copie du modèle avec des modifications
  AppointmentModel copyWith({
    String? id,
    String? clientId,
    String? providerId,
    String? serviceId,
    DateTime? dateTime,
    int? durationMinutes,
    AppointmentStatus? status,
    String? notes,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      providerId: providerId ?? this.providerId,
      serviceId: serviceId ?? this.serviceId,
      dateTime: dateTime ?? this.dateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: this.createdAt,
    );
  }
}