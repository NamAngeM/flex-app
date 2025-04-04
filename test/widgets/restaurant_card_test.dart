import 'package:flutter_test/flutter_test.dart';
import 'package:flexibook_app/widgets/restaurant_card.dart';
import 'package:flexibook_app/models/restaurant_model.dart';

void main() {
  testWidgets('Test de l\'affichage de RestaurantCard', (WidgetTester tester) async {
    // Créer un modèle de test
    final restaurant = RestaurantModel(
      id: '1',
      name: 'Le Gourmet',
      description: 'Un restaurant gastronomique à Paris',
      price: 50,
    );

    // Charger le widget
    await tester.pumpWidget(RestaurantCard(restaurant: restaurant));

    // Vérifier que les informations sont affichées
    expect(find.text('Le Gourmet'), findsOneWidget);
    expect(find.text('50€/personne'), findsOneWidget);
  });
}import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/widgets/search_widget.dart';

void main() {
  testWidgets('Test de saisie dans SearchWidget', (WidgetTester tester) async {
    // Charger le widget
    await tester.pumpWidget(SearchWidget(onSearch: (query) {}));

    // Saisir un terme de recherche
    await tester.enterText(find.byType(TextField), 'hôtel');
    await tester.pump();

    // Vérifier que le texte est bien saisi
    expect(find.text('hôtel'), findsOneWidget);
  });
}