// lib/screens/appointment_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import '../models/service_model.dart';
import '../services/service_service.dart';
import '../services/appointment_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importation de Firestore

class AppointmentDetailsScreen extends StatefulWidget {
  @override
  _AppointmentDetailsScreenState createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  final ServiceService _serviceService = ServiceService();
  final AppointmentService _appointmentService = AppointmentService();
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    late final AppointmentModel appointment;
    
    // Gérer différents types d'arguments
    if (args is AppointmentModel) {
      appointment = args;
    } else if (args is Map<String, dynamic>) {
      // Convertir la map en AppointmentModel
      appointment = AppointmentModel(
        id: args['id'] ?? '',
        clientId: args['clientId'] ?? '',
        providerId: args['providerId'] ?? '',
        serviceId: args['serviceId'] ?? '',
        dateTime: args['dateTime'] is DateTime 
          ? args['dateTime'] 
          : (args['dateTime'] is Timestamp 
              ? args['dateTime'].toDate() 
              : DateTime.now()),
        durationMinutes: args['durationMinutes'] ?? 60,
        status: _getStatusFromString(args['status']),
        notes: args['notes'],
        createdAt: args['createdAt'] is DateTime 
          ? args['createdAt'] 
          : (args['createdAt'] is Timestamp 
              ? args['createdAt'].toDate() 
              : DateTime.now()),
      );
    } else {
      // Fallback pour éviter les erreurs
      appointment = AppointmentModel(
        id: 'error',
        clientId: '',
        providerId: '',
        serviceId: '',
        dateTime: DateTime.now(),
        durationMinutes: 60,
        status: AppointmentStatus.pending,
        notes: 'Erreur de chargement du rendez-vous',
      );
      
      // Afficher un message d'erreur
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des détails du rendez-vous'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
    
    final dateFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm', 'fr_FR');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails du rendez-vous'),
        actions: [
          if (appointment.status == AppointmentStatus.pending || 
              appointment.status == AppointmentStatus.confirmed)
            IconButton(
              icon: Icon(Icons.cancel),
              onPressed: () => _showCancelDialog(context, appointment),
              tooltip: 'Annuler le rendez-vous',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statut du rendez-vous
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusColor(appointment.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getStatusColor(appointment.status),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(appointment.status),
                    color: _getStatusColor(appointment.status),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    _getStatusText(appointment.status),
                    style: TextStyle(
                      color: _getStatusColor(appointment.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Informations du service
            FutureBuilder<ServiceModel?>(
              future: _serviceService.getServiceById(appointment.serviceId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                final service = snapshot.data;
                final hasError = snapshot.hasError;
                
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: hasError
                        ? Center(
                            child: Text(
                              'Erreur lors du chargement du service',
                              style: TextStyle(color: Colors.red),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Service',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                service?.name ?? 'Service inconnu',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (service != null) ...[
                                SizedBox(height: 8),
                                Text(
                                  service.categoryId,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(Icons.euro, color: Theme.of(context).primaryColor),
                                    SizedBox(width: 8),
                                    Text(
                                      '${service.price.toStringAsFixed(2)} €',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                  ),
                );
              },
            ),
            
            SizedBox(height: 24),
            
            // Date et heure
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
                      'Date et heure',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          dateFormat.format(appointment.dateTime),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          timeFormat.format(appointment.dateTime),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ' (${appointment.durationMinutes} min)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Notes
            if (appointment.notes != null && appointment.notes!.isNotEmpty)
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
                        'Notes',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        appointment.notes!,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            SizedBox(height: 32),
            
            // Boutons d'action
            if (appointment.status == AppointmentStatus.pending || 
                appointment.status == AppointmentStatus.confirmed)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading 
                      ? null 
                      : () => _showCancelDialog(context, appointment),
                  icon: Icon(Icons.cancel),
                  label: Text('Annuler le rendez-vous'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, AppointmentModel appointment) {
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
            child: Text(
              'Oui, annuler',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAppointment(BuildContext context, AppointmentModel appointment) async {
    // Stocker une référence au BuildContext actuel
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _appointmentService.updateAppointmentStatus(
        appointment.id,
        AppointmentStatus.cancelled,
      );
      
      // Vérifier si le widget est toujours monté avant de mettre à jour l'état
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      // Utiliser la référence stockée au lieu de ScaffoldMessenger.of(context)
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Rendez-vous annulé avec succès')),
      );
      
      // Utiliser la référence stockée au lieu de Navigator.pop(context)
      navigator.pop();
    } catch (e) {
      // Vérifier si le widget est toujours monté avant de mettre à jour l'état
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      // Utiliser la référence stockée au lieu de ScaffoldMessenger.of(context)
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'annulation: $e')),
      );
    }
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.completed:
        return Colors.blue;
      case AppointmentStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'En attente';
      case AppointmentStatus.confirmed:
        return 'Confirmé';
      case AppointmentStatus.completed:
        return 'Terminé';
      case AppointmentStatus.cancelled:
        return 'Annulé';
      default:
        return 'Inconnu';
    }
  }

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Icons.hourglass_empty;
      case AppointmentStatus.confirmed:
        return Icons.check_circle;
      case AppointmentStatus.completed:
        return Icons.done_all;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  // Fonction utilitaire pour convertir une chaîne en AppointmentStatus
  AppointmentStatus _getStatusFromString(String? statusStr) {
    switch (statusStr?.toLowerCase()) {
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'completed':
        return AppointmentStatus.completed;
      case 'noshow':
      case 'no_show':
        return AppointmentStatus.noShow;
      case 'pending':
      default:
        return AppointmentStatus.pending;
    }
  }
}