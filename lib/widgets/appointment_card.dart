// lib/widgets/appointment_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import '../models/service_model.dart';
import '../services/service_service.dart';
import '../theme/app_theme.dart';
import 'modern_card.dart';
import 'skeleton_loader.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  
  const AppointmentCard({
    Key? key,
    required this.appointment,
    required this.onTap,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEE, d MMM yyyy • HH:mm', 'fr_FR');
    final serviceService = ServiceService();
    
    return FutureBuilder<ServiceModel?>(
      future: serviceService.getServiceById(appointment.serviceId),
      builder: (context, snapshot) {
        final service = snapshot.data;
        final bool hasError = snapshot.hasError;
        final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
        
        return ModernCard(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 3,
          shadowColor: _getStatusColor(appointment.status).withOpacity(0.2),
          backgroundColor: theme.cardColor,
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec statut et date
              Container(
                decoration: BoxDecoration(
                  color: _getStatusColor(appointment.status).withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _getStatusColor(appointment.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          _getStatusText(appointment.status),
                          style: TextStyle(
                            color: _getStatusColor(appointment.status),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      dateFormat.format(appointment.dateTime),
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Contenu principal
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informations du service
                    if (isLoading)
                      SkeletonText(
                        lines: 2,
                        height: 20,
                        lineSpacing: 8,
                      )
                    else if (hasError)
                      Text(
                        'Erreur de chargement du service',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else if (service != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image ou icône du service
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              image: service.imageUrl != null && service.imageUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(service.imageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: service.imageUrl == null || service.imageUrl!.isEmpty
                                ? Icon(
                                    Icons.business,
                                    size: 30,
                                    color: theme.colorScheme.primary,
                                  )
                                : null,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textTheme.titleLarge?.color,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  service.providerId,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.euro,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '${service.price.toStringAsFixed(2)} €',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Icon(
                                      Icons.schedule,
                                      size: 16,
                                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '${service.duration} min',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    
                    SizedBox(height: 16),
                    
                    // Informations supplémentaires
                    if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
                      Divider(),
                      SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.note,
                            size: 18,
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              appointment.notes!,
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    SizedBox(height: 16),
                    
                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (appointment.status == AppointmentStatus.confirmed || appointment.status == AppointmentStatus.pending) ...[
                          OutlinedButton.icon(
                            onPressed: onCancel,
                            icon: Icon(Icons.cancel_outlined, size: 20),
                            label: Text(
                              'Annuler',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                              backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                              side: BorderSide(color: theme.colorScheme.error, width: 1.5),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                        ],
                        ElevatedButton.icon(
                          onPressed: onTap,
                          icon: Icon(Icons.visibility_outlined, size: 18),
                          label: Text('Détails'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return AppTheme.successColor;
      case AppointmentStatus.pending:
        return AppTheme.warningColor;
      case AppointmentStatus.cancelled:
        return AppTheme.errorColor;
      case AppointmentStatus.completed:
        return AppTheme.primaryColor;
      default:
        return Colors.grey;
    }
  }
  
  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return 'Confirmé';
      case AppointmentStatus.pending:
        return 'En attente';
      case AppointmentStatus.cancelled:
        return 'Annulé';
      case AppointmentStatus.completed:
        return 'Terminé';
      default:
        return 'Inconnu';
    }
  }
}