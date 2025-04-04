import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flexibook_app/services/service_service.dart';

class MockServiceService extends Mock implements ServiceService {}

void main() {
  group('ServiceService Tests', () {
    late ServiceService serviceService;

    setUp(() {
      serviceService = MockServiceService();
    });

    test('Test searchServices avec terme valide', () async {
      // Simuler une réponse réussie
      when(serviceService.searchServices('hôtel')).thenAnswer((_) async => [/* données simulées */]);
      final result = await serviceService.searchServices('hôtel');
      expect(result, isNotEmpty);
    });

    test('Test searchServices avec terme invalide', () async {
      // Simuler une réponse vide
      when(serviceService.searchServices('invalid')).thenAnswer((_) async => []);
      final result = await serviceService.searchServices('invalid');
      expect(result, isEmpty);
    });
  });
}