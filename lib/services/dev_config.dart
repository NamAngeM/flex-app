// lib/services/dev_config.dart
import 'package:flutter/foundation.dart';

/// Classe qui centralise toutes les configurations de développement
class DevConfig {
  // Singleton pattern
  static final DevConfig _instance = DevConfig._internal();
  factory DevConfig() => _instance;
  DevConfig._internal();

  // Mode développement désactivé
  bool _devMode = false;
  
  // Options de configuration spécifiques
  bool _useTestUser = false;
  bool _generateTestData = false;
  bool _mockNetworkRequests = false;
  bool _showDebugLogs = true;
  
  // Délai de simulation pour les requêtes en mode développement (en millisecondes)
  int _mockDelay = 500;
  
  // Getters
  bool get isDevMode => _devMode;
  bool get useTestUser => _devMode && _useTestUser;
  bool get generateTestData => _devMode && _generateTestData;
  bool get mockNetworkRequests => _devMode && _mockNetworkRequests;
  bool get showDebugLogs => _devMode && _showDebugLogs;
  int get mockDelay => _mockDelay;
  
  // Setters
  set devMode(bool value) => _devMode = value;
  set useTestUser(bool value) => _useTestUser = value;
  set generateTestData(bool value) => _generateTestData = value;
  set mockNetworkRequests(bool value) => _mockNetworkRequests = value;
  set showDebugLogs(bool value) => _showDebugLogs = value;
  set mockDelay(int value) => _mockDelay = value;
  
  // Méthode pour activer/désactiver complètement le mode développement
  void setDevMode(bool enabled) {
    _devMode = enabled;
    if (kReleaseMode && enabled) {
      print('ATTENTION: Mode développement activé en production!');
    }
  }
  
  // Méthode pour logger des informations de débogage
  void log(String message) {
    if (showDebugLogs) {
      print('[DEV] $message');
    }
  }
  
  // Méthode pour simuler un délai réseau
  Future<void> simulateNetworkDelay() async {
    if (mockNetworkRequests) {
      await Future.delayed(Duration(milliseconds: _mockDelay));
    }
  }
  
  // Réinitialiser toutes les configurations à leurs valeurs par défaut
  void resetToDefaults() {
    _devMode = kDebugMode;
    _useTestUser = true;
    _generateTestData = true;
    _mockNetworkRequests = false;
    _showDebugLogs = true;
    _mockDelay = 500;
  }
}