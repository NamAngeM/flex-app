// lib/services/calendar_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:googleapis/calendar/v3.dart' as google_calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/appointment_model.dart';
import '../utils/config.dart';

class CalendarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Clés API pour Google Calendar - à charger depuis une source sécurisée
  static String get _clientId => AppConfig.googleClientId;
  static String get _clientSecret => AppConfig.googleClientSecret;
  static const List<String> _scopes = [google_calendar.CalendarApi.calendarScope];
  
  // Synchroniser un rendez-vous avec Google Calendar
  Future<String?> syncWithGoogleCalendar(AppointmentModel appointment) async {
    try {
      // Récupérer l'utilisateur actuel
      User? user = _auth.currentUser;
      if (user == null) return null;
      
      // Vérifier si l'utilisateur a autorisé Google Calendar
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      
      String? accessToken = userData['googleCalendarToken'];
      if (accessToken == null) {
        // L'utilisateur doit autoriser l'application
        return await _requestGoogleCalendarAuthorization(user.uid);
      }
      
      // Créer un client authentifié
      final client = http.Client();
      AccessCredentials credentials = AccessCredentials(
        AccessToken('Bearer', accessToken, DateTime.now().add(Duration(hours: 1))),
        null,
        _scopes,
      );
      
      var authenticatedClient = authenticatedClient(client, credentials);
      var calendar = google_calendar.CalendarApi(authenticatedClient);
      
      // Créer l'événement
      var event = google_calendar.Event()
        ..summary = 'RDV: ${appointment.serviceName}'
        ..description = appointment.notes
        ..start = google_calendar.EventDateTime()
          ..dateTime = appointment.dateTime.toDate()
          ..timeZone = 'Europe/Paris'
        ..end = google_calendar.EventDateTime()
          ..dateTime = appointment.endTime.toDate()
          ..timeZone = 'Europe/Paris'
        ..reminders = google_calendar.EventReminders()
          ..useDefault = true;
      
      // Ajouter l'événement au calendrier
      var createdEvent = await calendar.events.insert(event, 'primary');
      
      // Sauvegarder l'ID de l'événement Google Calendar
      await _firestore.collection('bookings').doc(appointment.id).update({
        'googleCalendarEventId': createdEvent.id,
      });
      
      return createdEvent.id;
    } catch (e) {
      print('Erreur lors de la synchronisation avec Google Calendar: $e');
      return null;
    }
  }
  
  // Demander l'autorisation pour Google Calendar
  Future<String?> _requestGoogleCalendarAuthorization(String userId) async {
    // Implémenter le flux d'autorisation OAuth2
    // Cette partie nécessite une implémentation spécifique à Flutter
    // et dépend de la façon dont vous souhaitez gérer l'autorisation
    
    // Exemple simplifié:
    final client = clientViaUserConsent(
      ClientId(_clientId, _clientSecret),
      _scopes,
      (url) async {
        // Ouvrir l'URL dans le navigateur
        await launchUrl(Uri.parse(url));
      },
    );
    
    // Sauvegarder le token dans Firestore
    final credentials = await client.credentials;
    await _firestore.collection('users').doc(userId).update({
      'googleCalendarToken': credentials.accessToken.data,
      'googleCalendarTokenExpiry': credentials.accessToken.expiry.toIso8601String(),
    });
    
    return credentials.accessToken.data;
  }
  
  // Synchroniser avec Apple Calendar (via fichier iCal)
  Future<String> exportToICalendar(AppointmentModel appointment) async {
    // Créer un fichier iCal (.ics)
    String iCalContent = '''
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//FlexBookRDV//FR
BEGIN:VEVENT
UID:${appointment.id}@flexbookrdv.com
DTSTAMP:${_formatDateForICal(DateTime.now())}
DTSTART:${_formatDateForICal(appointment.dateTime.toDate())}
DTEND:${_formatDateForICal(appointment.endTime.toDate())}
SUMMARY:RDV: ${appointment.serviceName}
DESCRIPTION:${appointment.notes}
STATUS:${appointment.status == 'confirmed' ? 'CONFIRMED' : 'TENTATIVE'}
BEGIN:VALARM
ACTION:DISPLAY
DESCRIPTION:Rappel de rendez-vous
TRIGGER:-PT1H
END:VALARM
END:VEVENT
END:VCALENDAR
''';
    
    // Sauvegarder le fichier localement
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/appointment_${appointment.id}.ics');
    await file.writeAsString(iCalContent);
    
    return file.path;
  }
  
  // Formater une date pour iCal
  String _formatDateForICal(DateTime date) {
    return date.toUtc().toIso8601String()
        .replaceAll('-', '')
        .replaceAll(':', '')
        .split('.')[0] + 'Z';
  }
  
  // Envoyer un rappel par email
  Future<bool> sendEmailReminder(AppointmentModel appointment, String recipientEmail) async {
    try {
      // Utiliser Firebase Cloud Functions ou un service d'email véritable
      if (AppConfig.useFirebaseFunctions) {
        // Appel à une fonction Firebase
        HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendEmailReminder');
        final result = await callable.call({
          'to': recipientEmail,
          'subject': 'Rappel de rendez-vous: ${appointment.serviceName}',
          'appointmentId': appointment.id,
        });
        
        return result.data['success'] == true;
      } else {
        // Implémentation alternative pour le développement
        print('Simulation d\'envoi d\'email à $recipientEmail pour le rendez-vous ${appointment.id}');
        return true;
      }
    } catch (e) {
      print('Erreur lors de l\'envoi du rappel par email: $e');
      return false;
    }
  }
  
  // Envoyer un rappel par SMS
  Future<bool> sendSmsReminder(AppointmentModel appointment, String phoneNumber) async {
    try {
      // Utiliser Firebase Cloud Functions ou un service SMS véritable
      if (AppConfig.useFirebaseFunctions) {
        // Appel à une fonction Firebase
        HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendSmsReminder');
        final result = await callable.call({
          'to': phoneNumber,
          'appointmentId': appointment.id,
        });
        
        return result.data['success'] == true;
      } else {
        // Implémentation alternative pour le développement
        print('Simulation d\'envoi de SMS à $phoneNumber pour le rendez-vous ${appointment.id}');
        return true;
      }
    } catch (e) {
      print('Erreur lors de l\'envoi du rappel par SMS: $e');
      return false;
    }
  }
  
  // Formater une date pour l'affichage
  String _formatDateForDisplay(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}