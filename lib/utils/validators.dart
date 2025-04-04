// Fichier: lib/utils/validators.dart
class Validators {
  // Validation d'email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  // Validation de mot de passe
  static Map<String, bool> validatePassword(String password) {
    return {
      'length': password.length >= 8,
      'uppercase': RegExp(r'[A-Z]').hasMatch(password),
      'lowercase': RegExp(r'[a-z]').hasMatch(password),
      'number': RegExp(r'[0-9]').hasMatch(password),
      'special': RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password),
    };
  }
  
  // Vérifier si le mot de passe est suffisamment fort
  static bool isStrongPassword(String password) {
    final validations = validatePassword(password);
    return !validations.values.contains(false);
  }
  
  // Validation de numéro de téléphone
  static bool isValidPhoneNumber(String phoneNumber) {
    // Format international avec ou sans +
    return RegExp(r'^(\+\d{1,3})?[\s.-]?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}$').hasMatch(phoneNumber);
  }
  
  // Validation de nom complet
  static bool isValidFullName(String fullName) {
    // Au moins deux mots, chacun d'au moins 2 caractères
    return RegExp(r'^[a-zA-ZÀ-ÿ]{2,}([\s-][a-zA-ZÀ-ÿ]{2,})+$').hasMatch(fullName);
  }
  
  // Validation de code postal français
  static bool isValidFrenchPostalCode(String postalCode) {
    return RegExp(r'^[0-9]{5}$').hasMatch(postalCode);
  }
}