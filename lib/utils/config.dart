// lib/utils/config.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class AppConfig {
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  static bool _initialized = false;
  
  // Initialiser la configuration
  static Future<void> initialize() async {
    if (_initialized) return;
    
    // Charger les variables d'environnement locales en développement
    if (kDebugMode) {
      await dotenv.load(fileName: '.env');
    }
    
    // Initialiser Remote Config pour la production
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    
    await _remoteConfig.fetchAndActivate();
    _initialized = true;
  }
  
  // Mode développement
  static bool get isDevelopment => kDebugMode;
  
  // Clés API Google
  static String get googleClientId {
    if (kDebugMode && dotenv.env['GOOGLE_CLIENT_ID'] != null) {
      return dotenv.env['GOOGLE_CLIENT_ID']!;
    }
    return _remoteConfig.getString('google_client_id');
  }
  
  static String get googleClientSecret {
    if (kDebugMode && dotenv.env['GOOGLE_CLIENT_SECRET'] != null) {
      return dotenv.env['GOOGLE_CLIENT_SECRET']!;
    }
    return _remoteConfig.getString('google_client_secret');
  }
  
  // Configuration des services
  static bool get useFirebaseFunctions {
    if (kDebugMode && dotenv.env['USE_FIREBASE_FUNCTIONS'] != null) {
      return dotenv.env['USE_FIREBASE_FUNCTIONS'] == 'true';
    }
    return _remoteConfig.getBool('use_firebase_functions');
  }
  
  // URLs des services
  static String get emailServiceUrl {
    if (kDebugMode && dotenv.env['EMAIL_SERVICE_URL'] != null) {
      return dotenv.env['EMAIL_SERVICE_URL']!;
    }
    return _remoteConfig.getString('email_service_url');
  }
  
  static String get smsServiceUrl {
    if (kDebugMode && dotenv.env['SMS_SERVICE_URL'] != null) {
      return dotenv.env['SMS_SERVICE_URL']!;
    }
    return _remoteConfig.getString('sms_service_url');
  }
}