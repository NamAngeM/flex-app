import 'package:flutter_test/flutter_test.dart';
import 'package:flexibook_app/models/restaurant_model.dart';

void main() {
  test('Test de création de RestaurantModel', () {
    final restaurant = RestaurantModel(
      id: '1',
      name: 'Le Gourmet',
      description: 'Un restaurant gastronomique à Paris',
      price: 50,
    );

    expect(restaurant.id, '1');
    expect(restaurant.name, 'Le Gourmet');
    expect(restaurant.description, 'Un restaurant gastronomique à Paris');
    expect(restaurant.price, 50);
  });

  test('Test de sérialisation de RestaurantModel', () {
    final restaurant = RestaurantModel(
      id: '1',
      name: 'Le Gourmet',
      description: 'Un restaurant gastronomique à Paris',
      price: 50,
    );

    final json = restaurant.toFirestore();
    expect(json['id'], '1');
    expect(json['name'], 'Le Gourmet');
    expect(json['description'], 'Un restaurant gastronomique à Paris');
    expect(json['price'], 50);
  });
}