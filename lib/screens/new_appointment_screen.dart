import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/service_model.dart';
import '../models/provider_model.dart';
import '../utils/app_colors.dart';
import '../services/appointment_service.dart';
import '../services/availability_service.dart';
import '../widgets/gradient_button.dart';

class NewAppointmentScreen extends StatefulWidget {
  final ServiceModel? initialService; // Service initial (optionnel)
  final ProviderModel? initialProvider; // Prestataire initial (optionnel)

  const NewAppointmentScreen({
    Key? key,
    this.initialService,
    this.initialProvider,
  }) : super(key: key);

  @override
  _NewAppointmentScreenState createState() => _NewAppointmentScreenState();
}

class _NewAppointmentScreenState extends State<NewAppointmentScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final AvailabilityService _availabilityService = AvailabilityService();
  
  ServiceModel? _selectedService;
  ProviderModel? _selectedProvider;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _notesController = TextEditingController();
  
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isLoadingTimeSlots = false;
  List<DateTime> _availableTimeSlots = [];

  @override
  void initState() {
    super.initState();
    // Initialiser avec les valeurs passées (si disponibles)
    _selectedService = widget.initialService;
    _selectedProvider = widget.initialProvider;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // Sélectionner un service
  Future<void> _selectService() async {
    try {
      // Naviguer vers l'écran de recherche avec le flag isForAppointment à true
      final result = await Navigator.pushNamed(
        context, 
        '/search',
        arguments: {'isForAppointment': true}
      );
      
      // Vérifier si un service a été sélectionné
      if (result is ServiceModel) {
        setState(() {
          _selectedService = result;
          // Réinitialiser le prestataire si le service change
          if (_selectedProvider != null && _selectedProvider!.id != result.providerId) {
            _selectedProvider = null;
          }
          // Reset time selection when service changes
          _selectedTime = null;
          _availableTimeSlots = [];
        });
        
        // Si le service a un prestataire associé, le sélectionner automatiquement
        if (result.providerId.isNotEmpty) {
          await _selectProviderFromService(result.providerId);
          
          // Load available time slots if date is selected
          if (_selectedDate != null) {
            _loadAvailableTimeSlots();
          }
        }
        
        // Log pour le débogage
        print('Service sélectionné: ${_selectedService!.name}, ID: ${_selectedService!.id}');
        print('Catégorie du service: ${_selectedService!.categoryId}');
      } else if (result != null) {
        print('Type de résultat inattendu: ${result.runtimeType}');
      }
    } catch (e) {
      print('Erreur lors de la sélection du service: $e');
      _showError('Impossible de sélectionner le service. Veuillez réessayer.');
    }
  }
  
  // Sélectionner automatiquement un prestataire à partir de l'ID du service
  Future<void> _selectProviderFromService(String providerId) async {
    try {
      // Simuler la sélection d'un prestataire pour le développement
      setState(() {
        _selectedProvider = ProviderModel(
          id: providerId,
          name: 'Prestataire de $providerId',
          email: 'provider@test.com',
          phone: '+33123456789',
          photoUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
        );
      });
      
      // Afficher un message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Prestataire sélectionné automatiquement'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Erreur lors de la sélection automatique du prestataire: $e');
    }
  }

  // Sélectionner un prestataire
  Future<void> _selectProvider() async {
    try {
      // Naviguer vers l'écran de sélection de prestataire
      final result = await Navigator.pushNamed(
        context,
        '/provider-selection',
        arguments: {'initialService': _selectedService},
      );
      
      // Vérifier si un prestataire a été sélectionné
      if (result is ProviderModel) {
        setState(() {
          _selectedProvider = result;
          // Reset time selection when provider changes
          _selectedTime = null;
          _availableTimeSlots = [];
        });
        
        // Load available time slots if date is selected
        if (_selectedDate != null && _selectedService != null) {
          _loadAvailableTimeSlots();
        }
        
        // Afficher un message de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prestataire sélectionné: ${_selectedProvider!.name}'),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Log pour le débogage
        print('Prestataire sélectionné: ${_selectedProvider!.name}, ID: ${_selectedProvider!.id}');
      }
    } catch (e) {
      print('Erreur lors de la sélection du prestataire: $e');
      _showError('Impossible de sélectionner le prestataire. Veuillez réessayer.');
    }
  }

  // Sélectionner une date
  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 90)),
      locale: Locale('fr', 'FR'),
    );
    
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _selectedTime = null; // Reset time selection
        _availableTimeSlots = []; // Reset available time slots
      });
      
      // Load available time slots if provider and service are selected
      if (_selectedProvider != null && _selectedService != null) {
        _loadAvailableTimeSlots();
      }
    }
  }

  // Charger les créneaux horaires disponibles
  Future<void> _loadAvailableTimeSlots() async {
    if (_selectedDate == null || _selectedProvider == null || _selectedService == null) {
      return;
    }
    
    setState(() {
      _isLoadingTimeSlots = true;
    });
    
    try {
      final availableSlots = await _availabilityService.getAvailableTimeSlots(
        providerId: _selectedProvider!.id,
        date: _selectedDate!,
        serviceDuration: _selectedService!.durationMinutes,
      );
      
      setState(() {
        _availableTimeSlots = availableSlots;
        _isLoadingTimeSlots = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des créneaux disponibles: $e');
      setState(() {
        _isLoadingTimeSlots = false;
      });
      _showError('Impossible de charger les créneaux disponibles');
    }
  }

  // Sélectionner une heure
  Future<void> _selectTime() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez d\'abord sélectionner une date'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // If we have available time slots, show them instead of the time picker
    if (_availableTimeSlots.isNotEmpty) {
      _showAvailableTimeSlotsDialog();
      return;
    }
    
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 9, minute: 0),
    );
    
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }
  
  // Afficher une boîte de dialogue avec les créneaux disponibles
  void _showAvailableTimeSlotsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Créneaux disponibles'),
          content: Container(
            width: double.maxFinite,
            child: _availableTimeSlots.isEmpty
                ? Text('Aucun créneau disponible pour cette date')
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _availableTimeSlots.map((slot) {
                        return ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedTime = TimeOfDay(hour: slot.hour, minute: slot.minute);
                            });
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            foregroundColor: Theme.of(context).colorScheme.primary,
                          ),
                          child: Text(
                            '${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  // Créer le rendez-vous
  Future<void> _createAppointment() async {
    setState(() {
      _isCreating = true;
    });
    
    // Vérifier que toutes les informations nécessaires sont présentes
    if (_selectedService == null) {
      _showError('Veuillez sélectionner un service');
      setState(() {
        _isCreating = false;
      });
      return;
    }
    
    if (_selectedProvider == null) {
      _showError('Veuillez sélectionner un prestataire');
      setState(() {
        _isCreating = false;
      });
      return;
    }
    
    if (_selectedDate == null) {
      _showError('Veuillez sélectionner une date');
      setState(() {
        _isCreating = false;
      });
      return;
    }
    
    if (_selectedTime == null) {
      _showError('Veuillez sélectionner une heure');
      setState(() {
        _isCreating = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Combiner la date et l'heure
      final DateTime appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      
      // Vérifier que le créneau est toujours disponible
      final isAvailable = await _availabilityService.isTimeSlotAvailable(
        providerId: _selectedProvider!.id,
        dateTime: appointmentDateTime,
        serviceDuration: _selectedService!.durationMinutes,
      );
      
      if (!isAvailable) {
        setState(() {
          _isLoading = false;
          _isCreating = false;
        });
        
        _showError('Ce créneau n\'est plus disponible. Veuillez en choisir un autre.');
        _loadAvailableTimeSlots(); // Reload available time slots
        return;
      }
      
      // Créer le rendez-vous
      final createdAppointment = await _appointmentService.createAppointment(
        appointmentData: {
          'serviceId': _selectedService!.id,
          'providerId': _selectedProvider!.id,
          'dateTime': appointmentDateTime,
          'durationMinutes': _selectedService!.durationMinutes,
          'notes': _notesController.text,
        }
      );
      
      setState(() {
        _isLoading = false;
        _isCreating = false;
      });
      
      // Naviguer vers l'écran de confirmation
      Navigator.pushNamed(
        context,
        '/appointment-confirmation',
        arguments: {
          'appointment': createdAppointment,
          'serviceName': _selectedService!.name,
          'providerName': _selectedProvider!.name,
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isCreating = false;
      });
      
      _showError('Erreur lors de la création du rendez-vous: $e');
    }
  }

  bool _canCreateAppointment() {
    return _selectedService != null && _selectedProvider != null && _selectedDate != null && _selectedTime != null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Nouveau rendez-vous'),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section d'information
                  Container(
                    margin: EdgeInsets.only(bottom: 24),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Veuillez remplir les informations pour prendre rendez-vous',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Étapes du rendez-vous
                  _buildSectionTitle(context, 'Détails du rendez-vous'),
                  
                  // Sélection du service
                  _buildSelectionCard(
                    context: context,
                    title: 'Service',
                    subtitle: _selectedService != null
                        ? _selectedService!.name
                        : 'Sélectionner un service',
                    icon: Icons.business,
                    onTap: _selectService,
                    isSelected: _selectedService != null,
                  ),
                  
                  // Sélection du prestataire
                  _buildSelectionCard(
                    context: context,
                    title: 'Prestataire',
                    subtitle: _selectedProvider != null
                        ? _selectedProvider!.name
                        : 'Sélectionner un prestataire',
                    icon: Icons.person,
                    onTap: _selectProvider,
                    isSelected: _selectedProvider != null,
                  ),
                  
                  // Sélection de la date
                  _buildSelectionCard(
                    context: context,
                    title: 'Date',
                    subtitle: _selectedDate != null
                        ? DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate!)
                        : 'Sélectionner une date',
                    icon: Icons.calendar_today,
                    onTap: _selectDate,
                    isSelected: _selectedDate != null,
                  ),
                  
                  // Sélection de l'heure
                  _buildSelectionCard(
                    context: context,
                    title: 'Heure',
                    subtitle: _selectedTime != null
                        ? _selectedTime!.format(context)
                        : _isLoadingTimeSlots
                            ? 'Chargement des créneaux disponibles...'
                            : 'Sélectionner une heure',
                    icon: Icons.access_time,
                    onTap: _selectTime,
                    isSelected: _selectedTime != null,
                    isLoading: _isLoadingTimeSlots,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Notes
                  _buildSectionTitle(context, 'Notes (optionnel)'),
                  Container(
                    margin: EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        hintText: 'Ajouter des notes pour votre rendez-vous...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      maxLines: 4,
                    ),
                  ),
                  
                  // Bouton de confirmation
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(vertical: 16),
                    child: ElevatedButton(
                      onPressed: _canCreateAppointment() ? _createAppointment : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isCreating
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: theme.colorScheme.onPrimary,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Création en cours...'),
                              ],
                            )
                          : Text('Confirmer le rendez-vous'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSelectionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isSelected = false,
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
                ? theme.colorScheme.primary.withOpacity(0.08)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onBackground.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.6),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onBackground,
                      ),
                    ),
                  ],
                ),
              ),
              isLoading
                  ? CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                      strokeWidth: 2,
                    )
                  : Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onBackground.withOpacity(0.4),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}