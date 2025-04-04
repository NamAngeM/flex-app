import 'package:cloud_firestore/cloud_firestore.dart';

enum MenuItemCategory {
  entree,      // Entrées
  plat,        // Plats principaux
  dessert,     // Desserts
  boisson,     // Boissons
  supplement,  // Suppléments
}

class MenuItemModel {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final MenuItemCategory category;
  final double price;
  final bool available;
  final List<String> allergens;
  final List<String> dietaryInfo;
  final String? imageUrl;
  final Map<String, double> options;
  final bool customizable;
  final int preparationTime;
  final bool spicy;
  final bool vegetarian;
  final bool vegan;
  final bool glutenFree;

  MenuItemModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    this.available = true,
    this.allergens = const [],
    this.dietaryInfo = const [],
    this.imageUrl,
    this.options = const {},
    this.customizable = false,
    this.preparationTime = 15,
    this.spicy = false,
    this.vegetarian = false,
    this.vegan = false,
    this.glutenFree = false,
  });

  factory MenuItemModel.fromFirestore(
    DocumentSnapshot snapshot,
    [String? id]
  ) {
    final data = snapshot.data() as Map<String, dynamic>;
    return MenuItemModel(
      id: id ?? snapshot.id,
      restaurantId: data['restaurantId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: MenuItemCategory.values[data['category'] ?? 0],
      price: (data['price'] ?? 0.0).toDouble(),
      available: data['available'] ?? true,
      allergens: List<String>.from(data['allergens'] ?? []),
      dietaryInfo: List<String>.from(data['dietaryInfo'] ?? []),
      imageUrl: data['imageUrl'],
      options: Map<String, double>.from(data['options'] ?? {}),
      customizable: data['customizable'] ?? false,
      preparationTime: data['preparationTime'] ?? 15,
      spicy: data['spicy'] ?? false,
      vegetarian: data['vegetarian'] ?? false,
      vegan: data['vegan'] ?? false,
      glutenFree: data['glutenFree'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      'description': description,
      'category': category.index,
      'price': price,
      'available': available,
      'allergens': allergens,
      'dietaryInfo': dietaryInfo,
      'imageUrl': imageUrl,
      'options': options,
      'customizable': customizable,
      'preparationTime': preparationTime,
      'spicy': spicy,
      'vegetarian': vegetarian,
      'vegan': vegan,
      'glutenFree': glutenFree,
    };
  }

  String getCategoryText() {
    switch (category) {
      case MenuItemCategory.entree:
        return 'Entrées';
      case MenuItemCategory.plat:
        return 'Plats principaux';
      case MenuItemCategory.dessert:
        return 'Desserts';
      case MenuItemCategory.boisson:
        return 'Boissons';
      case MenuItemCategory.supplement:
        return 'Suppléments';
    }
  }

  List<String> getDietaryInfo() {
    final List<String> info = [];
    if (vegetarian) info.add('Végétarien');
    if (vegan) info.add('Végétalien');
    if (glutenFree) info.add('Sans gluten');
    if (spicy) info.add('Épicé');
    return info;
  }

  String getFormattedPrice() {
    return '${price.toStringAsFixed(2)}€';
  }

  bool hasOptions() {
    return options.isNotEmpty;
  }

  double getOptionPrice(String optionName) {
    return options[optionName] ?? 0.0;
  }

  // Getters pour les propriétés diététiques
  bool get isVegetarian => vegetarian;
  bool get isVegan => vegan;
  bool get isGlutenFree => glutenFree;

  // Getter pour la disponibilité
  bool get isAvailable => available;

  // Getter pour le nom de la catégorie
  String get categoryName => getCategoryText();
}