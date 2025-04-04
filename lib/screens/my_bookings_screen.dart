import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/hotel_booking_model.dart';
import '../models/restaurant_booking_model.dart';
import '../services/hotel_service.dart';
import '../services/restaurant_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_message.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _errorMessage;
  List<HotelBookingModel> _hotelBookings = [];
  List<RestaurantBookingModel> _restaurantBookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final hotelService = Provider.of<HotelService>(context, listen: false);
      final restaurantService = Provider.of<RestaurantService>(context, listen: false);
      
      try {
        final hotelBookings = await hotelService.getUserBookings();
        final restaurantBookings = await restaurantService.getUserBookings();
        
        setState(() {
          _hotelBookings = hotelBookings;
          _restaurantBookings = restaurantBookings;
          _isLoading = false;
        });
      } catch (e) {
        // Vérifier si c'est une erreur d'authentification
        if (e.toString().contains('Utilisateur non connecté')) {
          setState(() {
            _errorMessage = 'Vous devez être connecté pour voir vos réservations';
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Erreur lors du chargement des réservations: $e';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur inattendue: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Mes réservations',
      ),
      drawer: null, 
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Hôtels'),
              Tab(text: 'Restaurants'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHotelBookingsTab(),
                _buildRestaurantBookingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelBookingsTab() {
    if (_isLoading) {
      return const LoadingIndicator();
    }

    if (_errorMessage != null) {
      return ErrorMessage(
        message: _errorMessage!,
        onRetry: _loadBookings,
      );
    }

    if (_hotelBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.hotel_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune réservation d\'hôtel trouvée',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vous n\'avez pas encore réservé d\'hôtel',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/hotels');
              },
              icon: const Icon(Icons.search),
              label: const Text('Découvrir nos hôtels'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _hotelBookings.length,
      itemBuilder: (context, index) {
        final booking = _hotelBookings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Réservation #${booking.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Du ${_formatDate(booking.checkInDate)} au ${_formatDate(booking.checkOutDate)}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '${booking.numberOfGuests} personnes, ${booking.numberOfRooms} chambre(s)',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: ${booking.totalPrice.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Statut: ${_getStatusText(booking.status)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: _getStatusColor(booking.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (booking.canBeCancelled()) ...[
                      TextButton(
                        onPressed: () => _cancelBooking(booking.id),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 8),
                    ],
                    ElevatedButton(
                      onPressed: () {
                        // Voir les détails de la réservation
                      },
                      child: const Text('Détails'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRestaurantBookingsTab() {
    if (_isLoading) {
      return const LoadingIndicator();
    }

    if (_errorMessage != null) {
      return ErrorMessage(
        message: _errorMessage!,
        onRetry: _loadBookings,
      );
    }

    if (_restaurantBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune réservation de restaurant trouvée',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vous n\'avez pas encore réservé de table',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/restaurants');
              },
              icon: const Icon(Icons.search),
              label: const Text('Découvrir nos restaurants'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _restaurantBookings.length,
      itemBuilder: (context, index) {
        final booking = _restaurantBookings[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.restaurant, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.restaurantName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatDate(booking.date)} - ${booking.time}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${booking.guestCount} personne${booking.guestCount > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Statut: ${booking.getStatusName()}',
                  style: TextStyle(
                    fontSize: 16,
                    color: booking.getStatusColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (booking.canBeCancelled()) ...[
                      TextButton(
                        onPressed: () => _cancelRestaurantBooking(booking.id),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 8),
                    ],
                    ElevatedButton(
                      onPressed: () {
                        // Voir les détails de la réservation
                      },
                      child: const Text('Détails'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'En attente';
      case BookingStatus.confirmed:
        return 'Confirmé';
      case BookingStatus.checkedIn:
        return 'Enregistré';
      case BookingStatus.checkedOut:
        return 'Terminé';
      case BookingStatus.cancelled:
        return 'Annulé';
      default:
        return 'Inconnu';
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.checkedIn:
        return Colors.blue;
      case BookingStatus.checkedOut:
        return Colors.purple;
      case BookingStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      final hotelService = Provider.of<HotelService>(context, listen: false);
      final success = await hotelService.cancelBooking(bookingId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation annulée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBookings();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'annulation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelRestaurantBooking(String bookingId) async {
    try {
      final restaurantService = Provider.of<RestaurantService>(context, listen: false);
      final success = await restaurantService.cancelBooking(bookingId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation annulée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBookings();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}