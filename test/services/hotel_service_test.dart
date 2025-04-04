import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flexibook_app/services/hotel_service.dart';

class MockHotelService extends Mock implements HotelService {}

void main() {
  group('HotelService Tests', () {
    late HotelService hotelService;

    setUp(() {
      hotelService = MockHotelService();
    });

    test('Test de recherche d\'hôtels', () async {
      when(hotelService.searchHotels('Paris')).thenAnswer((_) async => [/* données simulées */]);
      final result = await hotelService.searchHotels('Paris');
      expect(result, isNotEmpty);
    });

    test('Test de création de réservation', () async {
      when(hotelService.createBooking(any)).thenAnswer((_) async => true);
      final result = await hotelService.createBooking(/* données de test */);
      expect(result, isTrue);
    });
  });
}