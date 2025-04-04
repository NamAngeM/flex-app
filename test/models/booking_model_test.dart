import 'package:flutter_test/flutter_test.dart';
import 'package:flexibook_app/models/booking_model.dart';

void main() {
  test('Test de création de BookingModel', () {
    final booking = BookingModel(
      id: '1',
      userId: 'user123',
      serviceId: 'hotel456',
      date: DateTime(2025, 4, 10),
      status: BookingStatus.confirmed,
    );

    expect(booking.id, '1');
    expect(booking.userId, 'user123');
    expect(booking.serviceId, 'hotel456');
    expect(booking.date, DateTime(2025, 4, 10));
    expect(booking.status, BookingStatus.confirmed);
  });

  test('Test de sérialisation de BookingModel', () {
    final booking = BookingModel(
      id: '1',
      userId: 'user123',
      serviceId: 'hotel456',
      date: DateTime(2025, 4, 10),
      status: BookingStatus.confirmed,
    );

    final json = booking.toFirestore();
    expect(json['id'], '1');
    expect(json['userId'], 'user123');
    expect(json['serviceId'], 'hotel456');
    expect(json['date'], DateTime(2025, 4, 10).toIso8601String());
    expect(json['status'], 'confirmed');
  });
}