// lib/screens/appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';
import '../widgets/appointment_card.dart';

class AppointmentsScreen extends StatefulWidget {
  @override
  _AppointmentsScreenState createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AppointmentService _appointmentService = AppointmentService();
  int _selectedTab = 0;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Mes rendez-vous'),
        ),
        body: Center(
          child: Text('Vous devez être connecté pour voir vos rendez-vous'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes rendez-vous'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Tous'),
            Tab(text: 'À venir'),
            Tab(text: 'Passés'),
          ],
        ),
      ),
      body: _buildAppointmentList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/new-appointment'),
        child: Icon(Icons.add),
        tooltip: 'Prendre un rendez-vous',
      ),
    );
  }
  
  Widget _buildAppointmentList() {
    return StreamBuilder<List<AppointmentModel>>(
      stream: _appointmentService.getUserAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }
        
        // Filtrer les rendez-vous en fonction de l'onglet sélectionné
        final allAppointments = snapshot.data!;
        
        // Déboguer les rendez-vous reçus
        print('Nombre total de rendez-vous: ${allAppointments.length}');
        for (var appt in allAppointments) {
          print('Rendez-vous: ID=${appt.id}, Status=${appt.status}, ServiceID=${appt.serviceId}');
        }
        
        List<AppointmentModel> filteredAppointments;
        
        switch (_selectedTab) {
          case 0: // Tous
            filteredAppointments = allAppointments;
            break;
          case 1: // À venir
            filteredAppointments = allAppointments
                .where((appointment) => appointment.isUpcoming && 
                      (appointment.status == AppointmentStatus.confirmed || 
                       appointment.status == AppointmentStatus.pending))
                .toList();
            break;
          case 2: // Passés
            filteredAppointments = allAppointments
                .where((appointment) => !appointment.isUpcoming || 
                      (appointment.status == AppointmentStatus.completed || 
                       appointment.status == AppointmentStatus.cancelled ||
                       appointment.status == AppointmentStatus.noShow))
                .toList();
            break;
          default:
            filteredAppointments = allAppointments;
        }
        
        if (filteredAppointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'Aucun rendez-vous dans cette catégorie',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: filteredAppointments.length,
          itemBuilder: (context, index) {
            final appointment = filteredAppointments[index];
            // Vérifier que l'ID est valide avant de créer la carte
            if (appointment.id.isEmpty) {
              print('ATTENTION: Rendez-vous sans ID détecté dans la liste filtrée');
            }
            
            return AppointmentCard(
              appointment: appointment,
              onTap: () => Navigator.pushNamed(
                context,
                '/appointment-details',
                arguments: appointment,
              ),
              onCancel: appointment.status == AppointmentStatus.confirmed || 
                        appointment.status == AppointmentStatus.pending
                  ? () => _showCancelDialog(context, appointment)
                  : null,
            );
          },
        );
      },
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }
  
  Widget _buildErrorState(String error) {
    return Center(
      child: Text('Erreur: $error'),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Aucun rendez-vous',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  void _showCancelDialog(BuildContext context, AppointmentModel appointment) {
    // Vérifier que l'ID du rendez-vous n'est pas vide
    print('ID du rendez-vous à annuler: ${appointment.id}');
    print('Statut du rendez-vous: ${appointment.status}');
    print('Date du rendez-vous: ${appointment.dateTime}');
    print('Service ID: ${appointment.serviceId}');
    
    if (appointment.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ID du rendez-vous manquant')),
      );
      return;
    }
    
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(appointment.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ID du rendez-vous invalide')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Annuler le rendez-vous'),
        content: Text('Êtes-vous sûr de vouloir annuler ce rendez-vous ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Non'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelAppointment(context, appointment);
            },
            child: Text('Oui'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAppointment(BuildContext context, AppointmentModel appointment) async {
    // Stocker une référence au BuildContext actuel
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Afficher l'ID du rendez-vous pour le débogage
    print('Tentative d\'annulation du rendez-vous avec ID: ${appointment.id}');
    
    if (appointment.id.isEmpty) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Erreur: ID du rendez-vous manquant')),
      );
      return;
    }
    
    try {
      await _appointmentService.updateAppointmentStatus(
        appointment.id,
        AppointmentStatus.cancelled,
      );
      
      // Utiliser la référence stockée au lieu de ScaffoldMessenger.of(context)
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Rendez-vous annulé avec succès')),
      );
    } catch (e) {
      // Utiliser la référence stockée au lieu de ScaffoldMessenger.of(context)
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'annulation: $e')),
      );
    }
  }
}