import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flexibook_app/services/restaurant_service.dart';

class MockRestaurantService extends Mock implements RestaurantService {}

void main() {
  group('RestaurantService Tests', () {
    late RestaurantService restaurantService;

    setUp(() {
      restaurantService = MockRestaurantService();
    });

    test('Test de recherche de restaurants', () async {
      when(restaurantService.searchRestaurants('Paris')).thenAnswer((_) async => [/* données simulées */]);
      final result = await restaurantService.searchRestaurants('Paris');
      expect(result, isNotEmpty);
    });

    test('Test de création de réservation', () async {
      when(restaurantService.createBooking(any)).thenAnswer((_) async => true);
      final result = await restaurantService.createBooking(/* données de test */);
      expect(result, isTrue);
    });
  });
}