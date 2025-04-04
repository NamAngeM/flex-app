import 'package:flutter/material.dart';
import '../models/hotel_model.dart';
import '../services/hotel_service.dart';
import '../widgets/hotel_card.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_message.dart';
import 'hotel_details_screen.dart';

class HotelsScreen extends StatefulWidget {
  static const String routeName = '/hotels';

  @override
  _HotelsScreenState createState() => _HotelsScreenState();
}

class _HotelsScreenState extends State<HotelsScreen> {
  final HotelService _hotelService = HotelService();
  List<HotelModel> _hotels = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Filtres
  String _searchQuery = '';
  HotelCategory? _selectedCategory;
  Map<String, bool> _selectedServices = {
    'wifi': false,
    'breakfast': false,
    'parking': false,
    'pool': false,
  };
  double _minRating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadHotels();
  }

  Future<void> _loadHotels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final hotels = await _hotelService.getHotels(
        searchText: _searchQuery.isNotEmpty ? _searchQuery : null,
        categoryFilter: _selectedCategory,
        requiredServices: _getSelectedServices(),
        minRating: _minRating > 0 ? _minRating : null,
      );

      setState(() {
        _hotels = hotels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des hôtels: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, bool>? _getSelectedServices() {
    final selectedServices = Map<String, bool>.from(_selectedServices);
    final hasSelectedServices = selectedServices.values.any((selected) => selected);
    return hasSelectedServices ? selectedServices : null;
  }

  void _applyFilters() {
    _loadHotels();
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
      _selectedServices = {
        'wifi': false,
        'breakfast': false,
        'parking': false,
        'pool': false,
      };
      _minRating = 0.0;
    });
    _loadHotels();
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
                children: HotelCategory.values.map((category) {
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
                    selected: _selectedServices['wifi'] ?? false,
                    onSelected: (selected) {
                      setState(() {
                        _selectedServices['wifi'] = selected;
                      });
                    },
                  ),
                  FilterChip(
                    label: Text('Petit-déjeuner'),
                    selected: _selectedServices['breakfast'] ?? false,
                    onSelected: (selected) {
                      setState(() {
                        _selectedServices['breakfast'] = selected;
                      });
                    },
                  ),
                  FilterChip(
                    label: Text('Parking'),
                    selected: _selectedServices['parking'] ?? false,
                    onSelected: (selected) {
                      setState(() {
                        _selectedServices['parking'] = selected;
                      });
                    },
                  ),
                  FilterChip(
                    label: Text('Piscine'),
                    selected: _selectedServices['pool'] ?? false,
                    onSelected: (selected) {
                      setState(() {
                        _selectedServices['pool'] = selected;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
              
              // Note minimale
              Text(
                'Note minimale: ${_minRating.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
              
              // Boutons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _resetFilters();
                    },
                    child: Text('Réinitialiser'),
                  ),
                  SizedBox(width: 16),
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

  String _getCategoryName(HotelCategory category) {
    switch (category) {
      case HotelCategory.luxe: return 'Luxe';
      case HotelCategory.affaires: return 'Affaires';
      case HotelCategory.vacances: return 'Vacances';
      case HotelCategory.economique: return 'Économique';
      case HotelCategory.resort: return 'Resort';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Hôtels',
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
                hintText: 'Rechercher un hôtel...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                _searchQuery = value;
              },
              onSubmitted: (value) {
                _loadHotels();
              },
            ),
          ),
          
          // Contenu principal
          Expanded(
            child: _isLoading
                ? LoadingIndicator()
                : _errorMessage != null
                    ? ErrorMessage(message: _errorMessage!)
                    : _hotels.isEmpty
                        ? Center(
                            child: Text('Aucun hôtel trouvé'),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadHotels,
                            child: ListView.builder(
                              itemCount: _hotels.length,
                              itemBuilder: (context, index) {
                                final hotel = _hotels[index];
                                return HotelCard(
                                  hotel: hotel,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => HotelDetailsScreen(arguments: {'hotelId': hotel.id}),
                                      ),
                                    ).then((_) => _loadHotels());
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}