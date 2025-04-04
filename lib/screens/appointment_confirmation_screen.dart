// Fichier: lib/screens/appointment_confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/modern_card.dart';

class AppointmentConfirmationScreen extends StatelessWidget {
  final AppointmentModel appointment;
  final String? serviceName;
  final String? providerName;

  const AppointmentConfirmationScreen({
    Key? key, 
    required this.appointment,
    this.serviceName,
    this.providerName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirmation'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Animation de succès
            Container(
              width: 120,
              height: 120,
              margin: EdgeInsets.only(top: 16, bottom: 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 80,
                color: theme.colorScheme.primary,
              ),
            ),
            
            // Titre de confirmation
            Text(
              'Rendez-vous confirmé !',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 8),
            
            // Sous-titre
            Text(
              'Votre rendez-vous a été enregistré avec succès',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 32),
            
            // Détails du rendez-vous
            ModernCard(
              elevation: AppTheme.elevation_m,
              borderRadius: AppTheme.radius_l,
              padding: EdgeInsets.all(0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête de la carte
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppTheme.radius_l),
                        topRight: Radius.circular(AppTheme.radius_l),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_note,
                          color: Colors.white,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Détails du rendez-vous',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Contenu de la carte
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          context: context,
                          icon: Icons.business,
                          title: 'Service',
                          value: serviceName ?? 'Service non spécifié',
                        ),
                        Divider(),
                        _buildDetailRow(
                          context: context,
                          icon: Icons.person,
                          title: 'Prestataire',
                          value: providerName ?? 'Prestataire non spécifié',
                        ),
                        Divider(),
                        _buildDetailRow(
                          context: context,
                          icon: Icons.calendar_today,
                          title: 'Date',
                          value: DateFormat('EEEE d MMMM yyyy', 'fr_FR')
                              .format(appointment.dateTime),
                        ),
                        Divider(),
                        _buildDetailRow(
                          context: context,
                          icon: Icons.access_time,
                          title: 'Heure',
                          value: DateFormat('HH:mm', 'fr_FR')
                              .format(appointment.dateTime),
                        ),
                        if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
                          Divider(),
                          _buildDetailRow(
                            context: context,
                            icon: Icons.note,
                            title: 'Notes',
                            value: appointment.notes!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 32),
            
            // Informations supplémentaires
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppTheme.radius_m),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Informations importantes',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Vous recevrez un email de confirmation avec tous les détails de votre rendez-vous. Vous pouvez également retrouver ce rendez-vous dans votre espace personnel.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 32),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/appointments',
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radius_m),
                      ),
                    ),
                    child: Text('Voir mes rendez-vous'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: GradientButton(
                    text: 'Retour à l\'accueil',
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      );
                    },
                    isFullWidth: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}