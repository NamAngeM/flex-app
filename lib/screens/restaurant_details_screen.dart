import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/restaurant_model.dart';
import '../models/restaurant_table_model.dart';
import '../services/restaurant_service.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_message.dart';
import '../theme/app_theme.dart';
import 'restaurant_booking_screen.dart';

class RestaurantDetailsScreen extends StatefulWidget {
  static const String routeName = '/restaurant-details';

  final String restaurantId;

  const RestaurantDetailsScreen({
    Key? key,
    required this.restaurantId,
  }) : super(key: key);

  @override
  _RestaurantDetailsScreenState createState() => _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> with SingleTickerProviderStateMixin {
  final RestaurantService _restaurantService = RestaurantService();
  late TabController _tabController;
  
  RestaurantModel? _restaurant;
  List<RestaurantTableModel> _tables = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRestaurantDetails();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadRestaurantDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final restaurant = await _restaurantService.getRestaurantById(widget.restaurantId);
      if (restaurant != null) {
        final tables = await _restaurantService.getTablesByRestaurantId(widget.restaurantId);
        
        setState(() {
          _restaurant = restaurant;
          _tables = tables;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Restaurant non trouvé';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des détails du restaurant: $e';
        _isLoading = false;
      });
    }
  }
  
  void _navigateToBooking() {
    if (_restaurant != null) {
      Navigator.pushNamed(
        context,
        RestaurantBookingScreen.routeName,
        arguments: {
          'restaurantId': _restaurant!.id,
          'restaurantName': _restaurant!.name,
        },
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? LoadingIndicator()
          : _errorMessage != null
              ? ErrorMessage(
                  message: _errorMessage!,
                  onRetry: _loadRestaurantDetails,
                )
              : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    if (_restaurant == null) {
      return Center(
        child: Text('Aucune information disponible'),
      );
    }
    
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRestaurantInfo(),
              _buildTabBar(),
              _buildTabContent(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Image.network(
          _restaurant!.photoUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: Center(
                child: Icon(
                  Icons.restaurant,
                  size: 80,
                  color: Colors.grey[600],
                ),
              ),
            );
          },
        ),
        title: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _restaurant!.name,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        titlePadding: EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.favorite_border),
          onPressed: () {
            // Ajouter aux favoris
          },
        ),
        IconButton(
          icon: Icon(Icons.share),
          onPressed: () {
            // Partager
          },
        ),
      ],
    );
  }
  
  Widget _buildRestaurantInfo() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Catégorie et note
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _restaurant!.getCategoryName(),
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 20,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${_restaurant!.rating.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    ' (${_restaurant!.reviewCount})',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Adresse
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.grey[700],
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  _restaurant!.address,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          
          // Horaires
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.grey[700],
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                _getOpeningHours(),
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          
          // Téléphone
          Row(
            children: [
              Icon(
                Icons.phone,
                color: Colors.grey[700],
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                _restaurant!.phoneNumber,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Types de cuisine
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _restaurant!.cuisineTypes.map((cuisine) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  cuisine,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 16),
          
          // Services
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              if (_restaurant!.acceptsReservations)
                _buildFeature(Icons.event_available, 'Réservation'),
              if (_restaurant!.acceptsOnlineOrders)
                _buildFeature(Icons.shopping_bag, 'Commande en ligne'),
              if (_restaurant!.features['terrasse'] == true)
                _buildFeature(Icons.deck, 'Terrasse'),
              if (_restaurant!.features['wifi'] == true)
                _buildFeature(Icons.wifi, 'Wi-Fi'),
              if (_restaurant!.features['parking'] == true)
                _buildFeature(Icons.local_parking, 'Parking'),
              if (_restaurant!.features['climatisation'] == true)
                _buildFeature(Icons.ac_unit, 'Climatisation'),
            ],
          ),
          SizedBox(height: 24),
          
          // Bouton de réservation
          if (_restaurant!.acceptsReservations)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _navigateToBooking,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Réserver une table',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: AppTheme.primaryColor,
        tabs: [
          Tab(text: 'Menu'),
          Tab(text: 'Photos'),
          Tab(text: 'Avis'),
        ],
      ),
    );
  }
  
  Widget _buildTabContent() {
    return Container(
      height: 300, // Hauteur fixe pour le contenu des onglets
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildMenuTab(),
          _buildPhotosTab(),
          _buildReviewsTab(),
        ],
      ),
    );
  }
  
  Widget _buildMenuTab() {
    // Ici, vous pourriez charger et afficher le menu du restaurant
    return Center(
      child: Text(
        'Menu non disponible pour le moment',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[600],
        ),
      ),
    );
  }
  
  Widget _buildPhotosTab() {
    // Ici, vous pourriez charger et afficher les photos du restaurant
    return Center(
      child: Text(
        'Photos non disponibles pour le moment',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[600],
        ),
      ),
    );
  }
  
  Widget _buildReviewsTab() {
    // Ici, vous pourriez charger et afficher les avis du restaurant
    return Center(
      child: Text(
        'Avis non disponibles pour le moment',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[600],
        ),
      ),
    );
  }
  
  Widget _buildFeature(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey[700],
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
  
  String _getOpeningHours() {
    // Ici, vous pourriez formater les heures d'ouverture du restaurant
    // Pour l'exemple, nous utilisons une valeur statique
    final now = DateTime.now();
    final dayOfWeek = now.weekday; // 1 = Lundi, 7 = Dimanche
    
    if (dayOfWeek >= 1 && dayOfWeek <= 5) {
      return 'Aujourd\'hui: 11h30 - 14h30, 19h00 - 22h30';
    } else {
      return 'Aujourd\'hui: 11h30 - 15h00, 19h00 - 23h00';
    }
  }
}