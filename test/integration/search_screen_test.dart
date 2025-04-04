import 'package:flutter_test/flutter_test.dart';
import 'package:flexibook_app/main.dart' as app;
import 'package:flexibook_app/screens/search_screen.dart';

void main() {
  testWidgets('Test de recherche sur SearchScreen', (WidgetTester tester) async {
    // Lancer l'application
    app.main();

    // Attendre que l'écran de recherche soit chargé
    await tester.pumpAndSettle();

    // Saisir un terme de recherche
    await tester.enterText(find.byType(TextField), 'hôtel');
    await tester.pump();

    // Vérifier que les résultats sont affichés
    expect(find.text('Résultats pour "hôtel"'), findsOneWidget);
  });
}