import 'package:flutter_test/flutter_test.dart';
import 'package:flexibook_app/widgets/hotel_card.dart';
import 'package:flexibook_app/models/hotel_model.dart';

void main() {
  testWidgets('Test de l\'affichage de HotelCard', (WidgetTester tester) async {
    // Créer un modèle de test
    final hotel = HotelModel(
      id: '1',
      name: 'Hôtel de Luxe',
      description: 'Un hôtel de luxe à Paris',
      price: 200,
    );

    // Charger le widget
    await tester.pumpWidget(HotelCard(hotel: hotel));

    // Vérifier que les informations sont affichées
    expect(find.text('Hôtel de Luxe'), findsOneWidget);
    expect(find.text('200€/nuit'), findsOneWidget);
  });
}