import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum ErrorType {
  authentication,
  authorization,
  validation,
  network,
  database,
  booking,
  order,
  unknown,
}

class AppError implements Exception {
  final String message;
  final ErrorType type;
  final dynamic originalError;

  AppError(this.message, this.type, [this.originalError]);

  @override
  String toString() => message;
}

class ErrorHandler {
  static AppError handleError(dynamic error) {
    if (error is AppError) {
      return error;
    }

    if (error is FirebaseAuthException) {
      return _handleAuthError(error);
    }

    if (error is FirebaseException) {
      return _handleFirebaseError(error);
    }

    return AppError(
      'Une erreur inattendue s\'est produite',
      ErrorType.unknown,
      error,
    );
  }

  static AppError _handleAuthError(FirebaseAuthException error) {
    String message;
    switch (error.code) {
      case 'user-not-found':
        message = 'Utilisateur non trouvé';
        break;
      case 'wrong-password':
        message = 'Mot de passe incorrect';
        break;
      case 'invalid-email':
        message = 'Adresse e-mail invalide';
        break;
      case 'user-disabled':
        message = 'Ce compte a été désactivé';
        break;
      case 'email-already-in-use':
        message = 'Cette adresse e-mail est déjà utilisée';
        break;
      case 'operation-not-allowed':
        message = 'Opération non autorisée';
        break;
      case 'weak-password':
        message = 'Le mot de passe est trop faible';
        break;
      case 'requires-recent-login':
        message = 'Veuillez vous reconnecter pour effectuer cette action';
        break;
      default:
        message = 'Erreur d\'authentification';
    }
    return AppError(message, ErrorType.authentication, error);
  }

  static AppError _handleFirebaseError(FirebaseException error) {
    String message;
    ErrorType type;

    switch (error.code) {
      case 'permission-denied':
        message = 'Vous n\'avez pas les permissions nécessaires';
        type = ErrorType.authorization;
        break;
      case 'not-found':
        message = 'La ressource demandée n\'existe pas';
        type = ErrorType.database;
        break;
      case 'already-exists':
        message = 'Cette ressource existe déjà';
        type = ErrorType.database;
        break;
      case 'failed-precondition':
        message = 'Opération impossible dans l\'état actuel';
        type = ErrorType.validation;
        break;
      case 'unavailable':
        message = 'Service temporairement indisponible';
        type = ErrorType.network;
        break;
      default:
        message = 'Erreur de base de données';
        type = ErrorType.database;
    }
    return AppError(message, type, error);
  }

  // Erreurs spécifiques aux réservations
  static AppError bookingNotFound() {
    return AppError(
      'Réservation non trouvée',
      ErrorType.booking,
    );
  }

  static AppError bookingAlreadyExists() {
    return AppError(
      'Une réservation existe déjà pour cette période',
      ErrorType.booking,
    );
  }

  static AppError bookingCancellationTimeExpired() {
    return AppError(
      'Le délai d\'annulation est dépassé (24h minimum)',
      ErrorType.booking,
    );
  }

  static AppError bookingModificationTimeExpired() {
    return AppError(
      'Le délai de modification est dépassé (24h minimum)',
      ErrorType.booking,
    );
  }

  static AppError tableNotAvailable() {
    return AppError(
      'Cette table n\'est plus disponible',
      ErrorType.booking,
    );
  }

  static AppError invalidBookingTime() {
    return AppError(
      'L\'heure de réservation n\'est pas valide',
      ErrorType.booking,
    );
  }

  // Erreurs spécifiques aux commandes
  static AppError orderNotFound() {
    return AppError(
      'Commande non trouvée',
      ErrorType.order,
    );
  }

  static AppError orderCancellationTimeExpired() {
    return AppError(
      'Le délai d\'annulation est dépassé (30 min minimum)',
      ErrorType.order,
    );
  }

  static AppError orderModificationTimeExpired() {
    return AppError(
      'Le délai de modification de la commande est dépassé',
      ErrorType.order,
    );
  }

  static AppError restaurantClosed() {
    return AppError(
      'Le restaurant est fermé à cette heure',
      ErrorType.order,
    );
  }

  static AppError minimumOrderNotMet() {
    return AppError(
      'Le montant minimum de commande n\'est pas atteint',
      ErrorType.order,
    );
  }

  static AppError outOfDeliveryRange() {
    return AppError(
      'Adresse hors zone de livraison',
      ErrorType.order,
    );
  }

  static AppError insufficientLoyaltyPoints() {
    return AppError(
      'Points de fidélité insuffisants',
      ErrorType.validation,
    );
  }

  // Méthodes pour les erreurs spécifiques aux hôtels
  static AppError roomNotAvailable() {
    return AppError(
      'La chambre n\'est plus disponible pour ces dates',
      ErrorType.booking,
    );
  }

  static AppError cancellationDeadlinePassed() {
    return AppError(
      'Le délai d\'annulation est dépassé',
      ErrorType.booking,
    );
  }

  static AppError reviewRequiresStay() {
    return AppError(
      'Vous devez avoir séjourné à l\'hôtel pour laisser un avis',
      ErrorType.validation,
    );
  }

  // Méthode pour journaliser les erreurs
  static void logError(dynamic error, {String? context}) {
    final AppError appError = error is AppError ? error : handleError(error);
    
    // Format du message de log
    final String logMessage = [
      '🔴 ERREUR [${appError.type.toString().split('.').last}]',
      if (context != null) 'Contexte: $context',
      'Message: ${appError.message}',
      if (appError.originalError != null) 'Erreur originale: ${appError.originalError}',
      'Timestamp: ${DateTime.now().toIso8601String()}',
    ].join('\n');
    
    // Log dans la console pour le développement
    print(logMessage);
    
    // TODO: Implémenter la journalisation vers un service externe
    // comme Firebase Crashlytics ou un autre service de monitoring
  }
}