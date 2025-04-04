import 'package:flutter_test/flutter_test.dart';
import 'package:flexibook_app/models/hotel_model.dart';

void main() {
  test('Test de création de HotelModel', () {
    final hotel = HotelModel(
      id: '1',
      name: 'Hôtel de Luxe',
      description: 'Un hôtel de luxe à Paris',
      price: 200,
    );

    expect(hotel.id, '1');
    expect(hotel.name, 'Hôtel de Luxe');
    expect(hotel.description, 'Un hôtel de luxe à Paris');
    expect(hotel.price, 200);
  });

  test('Test de sérialisation de HotelModel', () {
    final hotel = HotelModel(
      id: '1',
      name: 'Hôtel de Luxe',
      description: 'Un hôtel de luxe à Paris',
      price: 200,
    );

    final json = hotel.toFirestore();
    expect(json['id'], '1');
    expect(json['name'], 'Hôtel de Luxe');
    expect(json['description'], 'Un hôtel de luxe à Paris');
    expect(json['price'], 200);
  });
}
