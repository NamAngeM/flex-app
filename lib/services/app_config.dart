// lib/services/app_config.dart
import 'package:flutter/material.dart';
import 'dev_config.dart';

class AppConfig {
  // Singleton pattern
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();
  
  // Configuration générale de l'application
  final String appName = 'FlexBook RDV';
  final String appVersion = '1.0.0';
  
  // Locale par défaut
  final Locale defaultLocale = Locale('fr', 'FR');
  
  // Timeouts (en secondes)
  final int connectionTimeout = 30;
  final int receiveTimeout = 30;
  
  // Tailles de page pour les listes paginées
  final int defaultPageSize = 20;
  
  // Accès au mode développement via DevConfig
  DevConfig _devConfig = DevConfig();
  DevConfig get devConfig => _devConfig;
  
  // Méthodes d'accès rapide aux configurations de développement
  bool isDevMode() => _devConfig.isDevMode;
  bool useTestUser() => _devConfig.useTestUser;
  bool generateTestData() => _devConfig.generateTestData;
  
  // Méthode pour initialiser la configuration
  Future<void> initialize() async {
    // Initialisation des configurations
    // Peut être utilisé pour charger des configurations depuis un fichier ou une API
  }
}