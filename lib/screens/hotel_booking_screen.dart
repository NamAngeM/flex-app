import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/hotel_model.dart';
import '../models/room_model.dart';
import '../models/hotel_booking_model.dart';
import '../models/user_model.dart';
import '../services/hotel_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_message.dart';
import '../theme/app_theme.dart';
import 'booking_confirmation_screen.dart';

class HotelBookingScreen extends StatefulWidget {
  final HotelModel hotel;
  final RoomModel room;

  const HotelBookingScreen({
    Key? key,
    required this.hotel,
    required this.room,
  }) : super(key: key);

  @override
  _HotelBookingScreenState createState() => _HotelBookingScreenState();
}

class _HotelBookingScreenState extends State<HotelBookingScreen> {
  final HotelService _hotelService = HotelService();
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  DateTime _checkInDate = DateTime.now().add(Duration(days: 1));
  DateTime _checkOutDate = DateTime.now().add(Duration(days: 3));
  int _numberOfGuests = 1;
  int _numberOfRooms = 1;
  
  Map<String, bool> _additionalServices = {
    'breakfast': false,
    'parking': false,
    'earlyCheckIn': false,
    'lateCheckOut': false,
  };
  
  final _specialRequestsController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _specialRequestsController.dispose();
    super.dispose();
  }

  // Calculer le prix total
  double _calculateTotalPrice() {
    // Prix de base pour la chambre
    double total = widget.room.price * _numberOfRooms * _getDaysCount();
    
    // Ajouter les services supplémentaires
    if (_additionalServices['breakfast'] == true) {
      total += 15.0 * _numberOfGuests * _getDaysCount(); // 15€ par personne par jour
    }
    if (_additionalServices['parking'] == true) {
      total += 10.0 * _getDaysCount(); // 10€ par jour
    }
    if (_additionalServices['earlyCheckIn'] == true) {
      total += 20.0; // 20€ pour early check-in
    }
    if (_additionalServices['lateCheckOut'] == true) {
      total += 20.0; // 20€ pour late check-out
    }
    
    return total;
  }
  
  // Obtenir le nombre de jours entre check-in et check-out
  int _getDaysCount() {
    return _checkOutDate.difference(_checkInDate).inDays;
  }

  // Sélectionner la date de check-in
  Future<void> _selectCheckInDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _checkInDate) {
      setState(() {
        _checkInDate = picked;
        // Assurer que la date de check-out est après la date de check-in
        if (_checkOutDate.isBefore(_checkInDate) || 
            _checkOutDate.isAtSameMomentAs(_checkInDate)) {
          _checkOutDate = _checkInDate.add(Duration(days: 1));
        }
      });
    }
  }

  // Sélectionner la date de check-out
  Future<void> _selectCheckOutDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkOutDate.isAfter(_checkInDate) 
          ? _checkOutDate 
          : _checkInDate.add(Duration(days: 1)),
      firstDate: _checkInDate.add(Duration(days: 1)),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _checkOutDate) {
      setState(() {
        _checkOutDate = picked;
      });
    }
  }

  // Soumettre la réservation
  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Vérifier que l'utilisateur est connecté
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        setState(() {
          _errorMessage = 'Vous devez être connecté pour effectuer une réservation.';
          _isLoading = false;
        });
        return;
      }
      
      // Vérifier la disponibilité
      final isAvailable = await _hotelService.checkRoomAvailability(
        widget.room.id,
        _checkInDate,
        _checkOutDate,
      );
      
      if (!isAvailable) {
        setState(() {
          _errorMessage = 'Cette chambre n\'est pas disponible pour les dates sélectionnées.';
          _isLoading = false;
        });
        return;
      }
      
      // Créer la réservation avec les informations de l'utilisateur connecté
      final totalPrice = _calculateTotalPrice();
      final guestDetails = {
        'name': currentUser.fullName,
        'email': currentUser.email,
        'phone': currentUser.phoneNumber,
      };
      
      final booking = await _hotelService.createHotelBooking(
        widget.hotel.id,
        widget.room.id,
        _checkInDate,
        _checkOutDate,
        _numberOfGuests,
        _numberOfRooms,
        _additionalServices,
        totalPrice,
        _specialRequestsController.text,
        guestDetails,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (booking != null) {
        // Naviguer vers l'écran de confirmation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BookingConfirmationScreen(
              booking: booking,
              hotelName: widget.hotel.name,
              roomName: widget.room.name,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Une erreur s\'est produite lors de la réservation.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Réserver une chambre'),
      ),
      body: _isLoading
          ? LoadingIndicator()
          : _errorMessage != null
              ? ErrorMessage(
                  message: _errorMessage!,
                  onRetry: () {
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final totalPrice = _calculateTotalPrice();
    
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Dates de séjour
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dates de séjour',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectCheckInDate,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Arrivée',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(dateFormat.format(_checkInDate)),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: _selectCheckOutDate,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Départ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(dateFormat.format(_checkOutDate)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Durée du séjour: ${_getDaysCount()} nuit${_getDaysCount() > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          
          // Nombre de voyageurs et de chambres
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voyageurs et chambres',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Nombre de voyageurs'),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline),
                            onPressed: _numberOfGuests > 1
                                ? () {
                                    setState(() {
                                      _numberOfGuests--;
                                    });
                                  }
                                : null,
                          ),
                          Text('$_numberOfGuests'),
                          IconButton(
                            icon: Icon(Icons.add_circle_outline),
                            onPressed: _numberOfGuests < widget.room.maxOccupancy * _numberOfRooms
                                ? () {
                                    setState(() {
                                      _numberOfGuests++;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Nombre de chambres'),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline),
                            onPressed: _numberOfRooms > 1
                                ? () {
                                    setState(() {
                                      _numberOfRooms--;
                                      // Ajuster le nombre de voyageurs si nécessaire
                                      if (_numberOfGuests > widget.room.maxOccupancy * _numberOfRooms) {
                                        _numberOfGuests = widget.room.maxOccupancy * _numberOfRooms;
                                      }
                                    });
                                  }
                                : null,
                          ),
                          Text('$_numberOfRooms'),
                          IconButton(
                            icon: Icon(Icons.add_circle_outline),
                            onPressed: () {
                              setState(() {
                                _numberOfRooms++;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          
          // Services supplémentaires
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Services supplémentaires',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  CheckboxListTile(
                    title: Text('Petit-déjeuner (15€ par personne par jour)'),
                    value: _additionalServices['breakfast'],
                    onChanged: (value) {
                      setState(() {
                        _additionalServices['breakfast'] = value ?? false;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: Text('Parking (10€ par jour)'),
                    value: _additionalServices['parking'],
                    onChanged: (value) {
                      setState(() {
                        _additionalServices['parking'] = value ?? false;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: Text('Early check-in (20€)'),
                    value: _additionalServices['earlyCheckIn'],
                    onChanged: (value) {
                      setState(() {
                        _additionalServices['earlyCheckIn'] = value ?? false;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: Text('Late check-out (20€)'),
                    value: _additionalServices['lateCheckOut'],
                    onChanged: (value) {
                      setState(() {
                        _additionalServices['lateCheckOut'] = value ?? false;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          
          // Demandes spéciales
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Demandes spéciales',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _specialRequestsController,
                    decoration: InputDecoration(
                      hintText: 'Exemple: chambre au calme, lit bébé, etc.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          
          // Résumé du prix
          Card(
            elevation: 3,
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Résumé du prix',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Prix de la chambre'),
                      Text('${(widget.room.price * _numberOfRooms * _getDaysCount()).toStringAsFixed(2)} €'),
                    ],
                  ),
                  if (_additionalServices['breakfast'] == true) ...[
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Petit-déjeuner'),
                        Text('${(15.0 * _numberOfGuests * _getDaysCount()).toStringAsFixed(2)} €'),
                      ],
                    ),
                  ],
                  if (_additionalServices['parking'] == true) ...[
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Parking'),
                        Text('${(10.0 * _getDaysCount()).toStringAsFixed(2)} €'),
                      ],
                    ),
                  ],
                  if (_additionalServices['earlyCheckIn'] == true) ...[
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Early check-in'),
                        Text('20.00 €'),
                      ],
                    ),
                  ],
                  if (_additionalServices['lateCheckOut'] == true) ...[
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Late check-out'),
                        Text('20.00 €'),
                      ],
                    ),
                  ],
                  Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Prix total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${totalPrice.toStringAsFixed(2)} €',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          
          // Bouton de réservation
          ElevatedButton(
            onPressed: _submitBooking,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Réserver maintenant',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}