import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales
  static const Color primaryColor = Color(0xFF3F51B5);
  static const Color primaryLightColor = Color(0xFF757DE8);
  static const Color primaryDarkColor = Color(0xFF002984);
  
  // Couleurs secondaires
  static const Color secondaryColor = Color(0xFFFF4081);
  static const Color secondaryLightColor = Color(0xFFFF79B0);
  static const Color secondaryDarkColor = Color(0xFFC60055);
  
  // Couleurs de fond
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  
  // Couleurs de texte
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color textHintColor = Color(0xFFBDBDBD);
  
  // Couleurs d'état
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color infoColor = Color(0xFF2196F3);
  
  // Couleurs pour les rendez-vous
  static const Color confirmedAppointmentColor = Color(0xFF66BB6A);
  static const Color pendingAppointmentColor = Color(0xFFFFB74D);
  static const Color cancelledAppointmentColor = Color(0xFFEF5350);
}

class AppSizes {
  // Padding et marges
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  
  // Tailles de texte
  static const double textXS = 12.0;
  static const double textS = 14.0;
  static const double textM = 16.0;
  static const double textL = 18.0;
  static const double textXL = 20.0;
  static const double textXXL = 24.0;
  static const double textHeadline = 30.0;
  
  // Tailles d'icônes
  static const double iconXS = 16.0;
  static const double iconS = 20.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;
  
  // Rayons de bordure
  static const double borderRadiusS = 4.0;
  static const double borderRadiusM = 8.0;
  static const double borderRadiusL = 16.0;
  static const double borderRadiusXL = 24.0;
  
  // Hauteurs de bouton
  static const double buttonHeightS = 36.0;
  static const double buttonHeightM = 48.0;
  static const double buttonHeightL = 56.0;
}

class AppStrings {
  // Titres d'écran
  static const String appName = 'FlexBook RDV';
  static const String homeTitle = 'Accueil';
  static const String appointmentsTitle = 'Rendez-vous';
  static const String profileTitle = 'Profil';
  static const String settingsTitle = 'Paramètres';
  
  // Messages d'erreur
  static const String errorGeneric = 'Une erreur s\'est produite. Veuillez réessayer.';
  static const String errorNetwork = 'Problème de connexion réseau. Veuillez vérifier votre connexion internet.';
  static const String errorAuth = 'Erreur d\'authentification. Veuillez vous reconnecter.';
  
  // Messages de succès
  static const String successProfileUpdate = 'Profil mis à jour avec succès';
  static const String successAppointmentBooked = 'Rendez-vous réservé avec succès';
  static const String successAppointmentCancelled = 'Rendez-vous annulé avec succès';
}