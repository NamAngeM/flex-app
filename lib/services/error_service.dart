// lib/services/error_service.dart
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

enum ErrorSeverity { low, medium, high, critical }

class ErrorService {
  static final ErrorService _instance = ErrorService._internal();
  
  factory ErrorService() => _instance;
  
  ErrorService._internal();
  
  // Gérer une erreur avec différents niveaux de gravité
  void handleError(
    dynamic error, {
    String? context,
    ErrorSeverity severity = ErrorSeverity.medium,
    StackTrace? stackTrace,
    BuildContext? buildContext,
  }) {
    // Journaliser l'erreur
    _logError(error, context: context, severity: severity, stackTrace: stackTrace);
    
    // Afficher un message à l'utilisateur si un contexte est fourni
    if (buildContext != null) {
      _showErrorToUser(buildContext, error, severity);
    }
  }
  
  // Journaliser l'erreur
  void _logError(
    dynamic error, {
    String? context,
    ErrorSeverity severity = ErrorSeverity.medium,
    StackTrace? stackTrace,
  }) {
    // Format du message d'erreur
    String errorMessage = 'ERREUR';
    if (context != null) errorMessage += ' dans $context';
    errorMessage += ': $error';
    
    // Journaliser en fonction de la gravité
    switch (severity) {
      case ErrorSeverity.low:
        print('INFO: $errorMessage');
        break;
      case ErrorSeverity.medium:
        print('AVERTISSEMENT: $errorMessage');
        // Enregistrer dans Crashlytics mais ne pas crasher l'app
        FirebaseCrashlytics.instance.recordError(
          error, 
          stackTrace, 
          reason: context,
          fatal: false,
        );
        break;
      case ErrorSeverity.high:
      case ErrorSeverity.critical:
        print('CRITIQUE: $errorMessage');
        // Enregistrer dans Crashlytics comme erreur fatale
        FirebaseCrashlytics.instance.recordError(
          error, 
          stackTrace, 
          reason: context,
          fatal: severity == ErrorSeverity.critical,
        );
        break;
    }
  }
  
  // Afficher un message d'erreur à l'utilisateur
  void _showErrorToUser(BuildContext context, dynamic error, ErrorSeverity severity) {
    String message;
    
    // Adapter le message en fonction de la gravité
    switch (severity) {
      case ErrorSeverity.low:
        message = 'Une erreur mineure s\'est produite.';
        break;
      case ErrorSeverity.medium:
        message = 'Une erreur s\'est produite. Veuillez réessayer.';
        break;
      case ErrorSeverity.high:
        message = 'Une erreur importante s\'est produite. Certaines fonctionnalités peuvent être indisponibles.';
        break;
      case ErrorSeverity.critical:
        message = 'Une erreur critique s\'est produite. L\'application va redémarrer.';
        break;
    }
    
    // Afficher un SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _getColorForSeverity(severity),
        duration: Duration(seconds: severity.index + 2),
        action: severity != ErrorSeverity.low ? SnackBarAction(
          label: 'Détails',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Détails de l\'erreur'),
                content: Text(error.toString()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Fermer'),
                  ),
                ],
              ),
            );
          },
        ) : null,
      ),
    );
  }
  
  // Obtenir une couleur en fonction de la gravité
  Color _getColorForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Colors.blue;
      case ErrorSeverity.medium:
        return Colors.orange;
      case ErrorSeverity.high:
        return Colors.deepOrange;
      case ErrorSeverity.critical:
        return Colors.red;
    }
  }
}