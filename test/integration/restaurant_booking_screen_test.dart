import 'package:flutter_test/flutter_test.dart';
import 'package:flexibook_app/main.dart' as app;
import 'package:flexibook_app/screens/restaurant_booking_screen.dart';
import 'package:flexibook_app/models/restaurant_model.dart';

void main() {
  testWidgets('Test de réservation de restaurant', (WidgetTester tester) async {
    // Lancer l'application
    app.main();

    // Créer un modèle de test
    final restaurant = RestaurantModel(
      id: '1',
      name: 'Le Gourmet',
      description: 'Un restaurant gastronomique à Paris',
      price: 50,
    );

    // Naviguer vers l'écran de réservation
    await tester.pumpWidget(RestaurantBookingScreen(restaurant: restaurant));
    await tester.pumpAndSettle();

    // Remplir le formulaire de réservation
    await tester.enterText(find.byKey(Key('dateField')), '2025-04-10');
    await tester.enterText(find.byKey(Key('timeField')), '19:00');
    await tester.enterText(find.byKey(Key('guestField')), '4');
    await tester.tap(find.text('Réserver'));
    await tester.pump();

    // Vérifier que la confirmation s'affiche
    expect(find.text('Réservation confirmée'), findsOneWidget);
  });
}