import 'package:flutter_test/flutter_test.dart';
import 'package:flexibook_app/widgets/search_widget.dart';

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