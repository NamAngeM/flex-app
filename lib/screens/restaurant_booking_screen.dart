import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/restaurant_booking_model.dart';
import '../models/restaurant_table_model.dart';
import '../services/restaurant_service.dart';
import '../services/auth_service.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_message.dart';
import '../theme/app_theme.dart';
import '../widgets/table_selection_widget.dart';

class RestaurantBookingScreen extends StatefulWidget {
  static const String routeName = '/restaurant-booking';

  final String restaurantId;
  final String restaurantName;

  const RestaurantBookingScreen({
    Key? key,
    required this.restaurantId,
    required this.restaurantName,
  }) : super(key: key);

  @override
  _RestaurantBookingScreenState createState() =>
      _RestaurantBookingScreenState();
}

class _RestaurantBookingScreenState extends State<RestaurantBookingScreen> {
  final RestaurantService _restaurantService = RestaurantService();
  final AuthService _authService = AuthService();

  // Contrôleurs pour les champs de formulaire
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _specialRequestsController =
      TextEditingController();

  // État du formulaire
  DateTime _selectedDate = DateTime.now().add(Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay(hour: 19, minute: 0);
  int _guestCount = 2;
  RestaurantTableModel? _selectedTable;

  // État de chargement
  bool _isLoading = false;
  bool _isLoadingTables = true;
  String? _errorMessage;

  // Tables disponibles
  List<RestaurantTableModel> _availableTables = [];

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    _loadAvailableTables();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  Future<void> _initializeUserData() async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      setState(() {
        _nameController.text = currentUser.displayName ?? '';
        _emailController.text = currentUser.email ?? '';
        _phoneController.text = currentUser.phoneNumber ?? '';
      });
    }
  }

  Future<void> _loadAvailableTables() async {
    setState(() {
      _isLoadingTables = true;
      _errorMessage = null;
    });

    try {
      final formattedTime =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      final tables = await _restaurantService.getAvailableTables(
        restaurantId: widget.restaurantId,
        date: _selectedDate,
        time: formattedTime,
        guestCount: _guestCount,
      );

      setState(() {
        _availableTables = tables;
        _selectedTable = tables.isNotEmpty ? tables.first : null;
        _isLoadingTables = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des tables disponibles: $e';
        _isLoadingTables = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
      locale: Locale('fr', 'FR'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadAvailableTables();
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      _loadAvailableTables();
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner une table'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final formattedTime =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      final booking = RestaurantBookingModel(
        id: '',
        restaurantId: widget.restaurantId,
        restaurantName: widget.restaurantName,
        userId: await _authService.getCurrentUserId() ?? '',
        tableId: _selectedTable!.id,
        date: _selectedDate,
        time: formattedTime,
        guestCount: _guestCount,
        customerName: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        specialRequests: _specialRequestsController.text,
        status: RestaurantBookingStatus.confirmed,
        createdAt: DateTime.now(),
      );

      final bookingResult = await _restaurantService.createBooking(booking);

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Réservation confirmée avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      // Retourner à l'écran précédent après un court délai
      Future.delayed(Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la réservation: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Réserver une table'),
      ),
      body: _isLoading
          ? LoadingIndicator()
          : _errorMessage != null
              ? ErrorMessage(
                  message: _errorMessage!,
                  onRetry: _loadAvailableTables,
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Text(
            widget.restaurantName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),

          // Date et heure
          Text(
            'Date et heure',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Heure',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(
                      '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Nombre de personnes
          Text(
            'Nombre de personnes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove_circle_outline),
                onPressed: _guestCount > 1
                    ? () {
                        setState(() {
                          _guestCount--;
                        });
                        _loadAvailableTables();
                      }
                    : null,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$_guestCount ${_guestCount > 1 ? 'personnes' : 'personne'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_circle_outline),
                onPressed: _guestCount < 20
                    ? () {
                        setState(() {
                          _guestCount++;
                        });
                        _loadAvailableTables();
                      }
                    : null,
              ),
            ],
          ),
          SizedBox(height: 24),

          // Sélection de table
          Text(
            'Table disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _isLoadingTables
              ? Center(child: CircularProgressIndicator())
              : _availableTables.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune table disponible pour cette date et cette heure',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : TableSelectionWidget(
                      tables: _availableTables,
                      selectedTable: _selectedTable,
                      onTableSelected: (table) {
                        setState(() {
                          _selectedTable = table;
                        });
                      },
                    ),
          SizedBox(height: 24),

          // Informations de contact
          Text(
            'Informations de contact',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nom complet *',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email *',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Téléphone *',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 24),

          // Demandes spéciales
          Text(
            'Demandes spéciales',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _specialRequestsController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Demandes spéciales (optionnel)',
              border: OutlineInputBorder(),
              hintText:
                  'Ex: allergies, occasion spéciale, préférences de placement...',
            ),
          ),
          SizedBox(height: 32),

          // Bouton de confirmation
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _availableTables.isEmpty ? null : _submitBooking,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Confirmer la réservation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}
