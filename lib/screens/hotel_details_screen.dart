import 'package:flutter/material.dart';
import '../models/hotel_model.dart';
import '../models/room_model.dart';
import '../services/hotel_service.dart';
import '../widgets/room_card.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_message.dart';
import '../widgets/custom_button.dart';
import 'hotel_booking_screen.dart';

class HotelDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const HotelDetailsScreen({
    Key? key,
    this.arguments,
  }) : super(key: key);

  @override
  _HotelDetailsScreenState createState() => _HotelDetailsScreenState();
}

class _HotelDetailsScreenState extends State<HotelDetailsScreen> {
  final HotelService _hotelService = HotelService();
  
  String? _hotelId;
  HotelModel? _hotel;
  List<RoomModel> _rooms = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _checkInDate = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 2));

  @override
  void initState() {
    super.initState();
    _getArgumentsAndLoadData();
  }

  void _getArgumentsAndLoadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = widget.arguments ?? 
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      
      if (args == null) {
        setState(() {
          _errorMessage = 'Aucun hôtel spécifié';
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _hotelId = args['hotelId'] as String?;
      });
      
      if (_hotelId == null) {
        setState(() {
          _errorMessage = 'Identifiant d\'hôtel invalide';
          _isLoading = false;
        });
        return;
      }
      
      _loadHotelDetails();
    });
  }

  Future<void> _loadHotelDetails() async {
    if (_hotelId == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Charger les détails de l'hôtel
      final hotel = await _hotelService.getHotelById(_hotelId!);
      if (hotel == null) {
        setState(() {
          _errorMessage = 'Hôtel non trouvé';
          _isLoading = false;
        });
        return;
      }

      // Charger les chambres de l'hôtel
      final rooms = await _hotelService.getRoomsByHotelId(_hotelId!);

      setState(() {
        _hotel = hotel;
        _rooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des détails de l\'hôtel: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_hotel?.name ?? 'Détails de l\'hôtel'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (_hotelId != null) {
                            _loadHotelDetails();
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: Text(_hotelId != null ? 'Réessayer' : 'Retour'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
      floatingActionButton: (_hotel != null && _rooms.isNotEmpty)
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToBooking(_rooms.first),
              label: Text('Réserver maintenant'),
              icon: Icon(Icons.book_online),
              backgroundColor: Theme.of(context).primaryColor,
            )
          : null,
    );
  }

  void _navigateToBooking(RoomModel room) {
    Navigator.pushNamed(
      context,
      '/hotel-booking',
      arguments: {
        'hotel': _hotel,
        'room': room,
        'checkInDate': _checkInDate,
        'checkOutDate': _checkOutDate,
      },
    );
  }

  Widget _buildContent() {
    if (_hotel == null) {
      return Center(
        child: Text(
          'Aucune information d\'hôtel disponible',
          style: TextStyle(fontSize: 16),
        ),
      );
    }
    
    return CustomScrollView(
      slivers: [
        // App bar avec image
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              _hotel!.name,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ],
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  _hotel!.photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.hotel,
                        size: 80,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
                // Gradient pour améliorer la lisibilité du titre
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: [0.7, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Contenu
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations générales
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _hotel!.getCategoryName(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 18,
                          color: Colors.amber,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _hotel!.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Description
                Text(
                  _hotel!.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Services
                Text(
                  'Services',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: _buildServiceItems(),
                ),
                
                SizedBox(height: 24),
                
                // Chambres disponibles
                Text(
                  'Chambres disponibles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                
                if (_rooms.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        'Aucune chambre disponible pour le moment',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _rooms.length,
                    itemBuilder: (context, index) {
                      final room = _rooms[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: RoomCard(
                          room: room,
                          onTap: () => _navigateToBooking(room),
                        ),
                      );
                    },
                  ),
                
                SizedBox(height: 24),
                
                // Bouton de réservation
                if (_rooms.isNotEmpty)
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToBooking(_rooms.first),
                      icon: Icon(Icons.book_online),
                      label: Text('Réserver maintenant'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        textStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildServiceItems() {
    final List<Widget> serviceWidgets = [];
    
    if (_hotel == null) return serviceWidgets;
    
    final Map<String, dynamic> services = _hotel!.services;
    
    // Vérifier chaque service et l'ajouter s'il est disponible
    if (services['wifi'] == true)
      serviceWidgets.add(_buildServiceItem(Icons.wifi, 'Wi-Fi'));
    
    if (services['parking'] == true)
      serviceWidgets.add(_buildServiceItem(Icons.local_parking, 'Parking'));
    
    if (services['breakfast'] == true)
      serviceWidgets.add(_buildServiceItem(Icons.free_breakfast, 'Petit-déjeuner'));
    
    if (services['pool'] == true)
      serviceWidgets.add(_buildServiceItem(Icons.pool, 'Piscine'));
    
    if (services['spa'] == true)
      serviceWidgets.add(_buildServiceItem(Icons.spa, 'Spa'));
    
    if (services['gym'] == true)
      serviceWidgets.add(_buildServiceItem(Icons.fitness_center, 'Salle de sport'));
    
    if (services['roomService'] == true)
      serviceWidgets.add(_buildServiceItem(Icons.room_service, 'Service en chambre'));
    
    return serviceWidgets;
  }

  Widget _buildServiceItem(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).primaryColor,
          ),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}