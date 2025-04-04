import 'package:flutter_test/flutter_test.dart';
import 'package:flexibook_app/main.dart' as app;
import 'package:flexibook_app/screens/hotel_booking_screen.dart';
import 'package:flexibook_app/models/hotel_model.dart';

void main() {
  testWidgets('Test de réservation d\'hôtel', (WidgetTester tester) async {
    // Lancer l'application
    app.main();

    // Créer un modèle de test
    final hotel = HotelModel(
      id: '1',
      name: 'Hôtel de Luxe',
      description: 'Un hôtel de luxe à Paris',
      price: 200,
    );

    // Naviguer vers l'écran de réservation
    await tester.pumpWidget(HotelBookingScreen(hotel: hotel));
    await tester.pumpAndSettle();

    // Remplir le formulaire de réservation
    await tester.enterText(find.byKey(Key('dateField')), '2025-04-10');
    await tester.enterText(find.byKey(Key('guestField')), '2');
    await tester.tap(find.text('Réserver'));
    await tester.pump();

    // Vérifier que la confirmation s'affiche
    expect(find.text('Réservation confirmée'), findsOneWidget);
  });
}