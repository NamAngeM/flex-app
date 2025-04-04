// lib/l10n/app_localizations.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // Chaînes localisées
  String get appTitle => 'FlexBook RDV';
  
  String get loginTitle => 'Connexion';
  String get emailHint => 'Email';
  String get passwordHint => 'Mot de passe';
  String get loginButton => 'Se connecter';
  String get forgotPassword => 'Mot de passe oublié ?';
  String get signUpPrompt => 'Pas encore de compte ?';
  String get signUpButton => 'S\'inscrire';
  
  String get homeWelcome => 'Bienvenue sur FlexBook RDV';
  String get upcomingAppointments => 'Prochains rendez-vous';
  String get popularServices => 'Services populaires';
  String get searchHint => 'Rechercher un service';
  
  // Format de date et heure
  String formatDate(DateTime date) {
    return DateFormat.yMMMMd(locale.toString()).format(date);
  }
  
  String formatTime(DateTime time) {
    return DateFormat.Hm(locale.toString()).format(time);
  }
  
  String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} à ${formatTime(dateTime)}';
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['fr', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}