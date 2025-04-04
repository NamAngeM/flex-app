import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';
import '../services/restaurant_service.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_message.dart';

class RestaurantsScreen extends StatefulWidget {
  static const String routeName = '/restaurants';

  @override
  _RestaurantsScreenState createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  final RestaurantService _restaurantService = RestaurantService();
  List<RestaurantModel> _restaurants = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Filtres
  String _searchQuery = '';
  RestaurantCategory? _selectedCategory;
  List<String> _selectedCuisines = [];
  Map<String, bool> _selectedFeatures = {
    'wifi': false,
    'terrasse': false,
    'parking': false,
    'climatisation': false,
  };
  double _minRating = 0.0;
  bool _onlyReservation = false;
  bool _onlyOnlineOrder = false;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final restaurants = await _restaurantService.getRestaurants(
        searchText: _searchQuery.isNotEmpty ? _searchQuery : null,
        categoryFilter: _selectedCategory,
        cuisineFilters: _selectedCuisines.isNotEmpty ? _selectedCuisines : null,
        requiredFeatures: _getSelectedFeatures(),
        minRating: _minRating > 0 ? _minRating : null,
        mustAcceptReservations: _onlyReservation ? true : null,
        mustAcceptOnlineOrders: _onlyOnlineOrder ? true : null,
      );

      setState(() {
        _restaurants = restaurants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des restaurants: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, bool>? _getSelectedFeatures() {
    final selectedFeatures = Map<String, bool>.from(_selectedFeatures);
    final hasSelectedFeatures = selectedFeatures.values.any((selected) => selected);
    return hasSelectedFeatures ? selectedFeatures : null;
  }

  void _applyFilters() {
    _loadRestaurants();
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
      _selectedCuisines = [];
      _selectedFeatures = {
        'wifi': false,
        'terrasse': false,
        'parking': false,
        'climatisation': false,
      };
      _minRating = 0.0;
      _onlyReservation = false;
      _onlyOnlineOrder = false;
    });
    _loadRestaurants();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtres',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              
              // Catégorie
              Text(
                'Catégorie',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: RestaurantCategory.values.map((category) {
                  return ChoiceChip(
                    label: Text(_getCategoryName(category)),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : null;
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              
              // Services
              Text(
                'Services',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text('Wi-Fi'),
                    selected: _selectedFeatures['wifi'] ?? false,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFeatures['wifi'] = selected;
                      });
                    },
                  ),
                  FilterChip(
                    label: Text('Terrasse'),
                    selected: _selectedFeatures['terrasse'] ?? false,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFeatures['terrasse'] = selected;
                      });
                    },
                  ),
                  FilterChip(
                    label: Text('Parking'),
                    selected: _selectedFeatures['parking'] ?? false,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFeatures['parking'] = selected;
                      });
                    },
                  ),
                  FilterChip(
                    label: Text('Climatisation'),
                    selected: _selectedFeatures['climatisation'] ?? false,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFeatures['climatisation'] = selected;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
              
              // Note minimale
              Text(
                'Note minimale',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Slider(
                value: _minRating,
                min: 0,
                max: 5,
                divisions: 10,
                label: _minRating.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    _minRating = value;
                  });
                },
              ),
              SizedBox(height: 20),
              
              // Options supplémentaires
              CheckboxListTile(
                title: Text('Accepte les réservations'),
                value: _onlyReservation,
                onChanged: (value) {
                  setState(() {
                    _onlyReservation = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              CheckboxListTile(
                title: Text('Commande en ligne disponible'),
                value: _onlyOnlineOrder,
                onChanged: (value) {
                  setState(() {
                    _onlyOnlineOrder = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              SizedBox(height: 20),
              
              // Boutons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _resetFilters();
                    },
                    child: Text('Réinitialiser'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _applyFilters();
                    },
                    child: Text('Appliquer'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getCategoryName(RestaurantCategory category) {
    switch (category) {
      case RestaurantCategory.gastronomique:
        return 'Gastronomique';
      case RestaurantCategory.traditionnel:
        return 'Traditionnel';
      case RestaurantCategory.rapide:
        return 'Rapide';
      case RestaurantCategory.italien:
        return 'Italien';
      case RestaurantCategory.asiatique:
        return 'Asiatique';
      case RestaurantCategory.vegetarien:
        return 'Végétarien';
      case RestaurantCategory.autre:
        return 'Autre';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Restaurants',
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      drawer: CustomDrawer(),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un restaurant...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                _searchQuery = value;
              },
              onSubmitted: (value) {
                _loadRestaurants();
              },
            ),
          ),
          
          // Filtres actifs
          if (_selectedCategory != null || _getSelectedFeatures() != null || _minRating > 0 || _onlyReservation || _onlyOnlineOrder)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Filtres actifs:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_selectedCategory != null)
                            _buildActiveFilterChip(_getCategoryName(_selectedCategory!)),
                          if (_minRating > 0)
                            _buildActiveFilterChip('${_minRating.toStringAsFixed(1)}★+'),
                          if (_onlyReservation)
                            _buildActiveFilterChip('Réservation'),
                          if (_onlyOnlineOrder)
                            _buildActiveFilterChip('Commande en ligne'),
                          for (final entry in _selectedFeatures.entries)
                            if (entry.value)
                              _buildActiveFilterChip(entry.key == 'wifi' ? 'Wi-Fi' : 
                                                    entry.key == 'terrasse' ? 'Terrasse' : 
                                                    entry.key == 'parking' ? 'Parking' : 'Climatisation'),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: _resetFilters,
                    iconSize: 18,
                  ),
                ],
              ),
            ),
          
          // Contenu principal
          Expanded(
            child: _isLoading
                ? LoadingIndicator()
                : _errorMessage != null
                    ? ErrorMessage(
                        message: _errorMessage!,
                        onRetry: _loadRestaurants,
                      )
                    : _restaurants.isEmpty
                        ? Center(
                            child: Text(
                              'Aucun restaurant ne correspond à vos critères',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            itemCount: _restaurants.length,
                            itemBuilder: (context, index) {
                              final restaurant = _restaurants[index];
                              return RestaurantCard(
                                restaurant: restaurant,
                                onTap: () {
                                  // Navigation vers l'écran de détails du restaurant
                                  // Nous implémenterons cette partie plus tard
                                  /*
                                  Navigator.pushNamed(
                                    context,
                                    RestaurantDetailsScreen.routeName,
                                    arguments: restaurant.id,
                                  );
                                  */
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip(String label) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[800],
        ),
      ),
    );
  }
}