// lib/screens/calendar_integration_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/calendar_service.dart';
import '../models/appointment_model.dart';
import '../services/database_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarIntegrationScreen extends StatefulWidget {
  const CalendarIntegrationScreen({Key? key}) : super(key: key);

  @override
  _CalendarIntegrationScreenState createState() => _CalendarIntegrationScreenState();
}

class _CalendarIntegrationScreenState extends State<CalendarIntegrationScreen> {
  final CalendarService _calendarService = CalendarService();
  final DatabaseService _databaseService = DatabaseService();
  bool _isGoogleCalendarConnected = false;
  bool _isAppleCalendarEnabled = false;
  bool _isLoading = true;
  List<AppointmentModel> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAppointments();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _isGoogleCalendarConnected = userData['googleCalendarToken'] != null;
            _isAppleCalendarEnabled = userData['appleCalendarEnabled'] == true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des données utilisateur: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAppointments() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        List<AppointmentModel> appointments;
        
        // Charger les rendez-vous en fonction du rôle de l'utilisateur
        var userModel = await _databaseService.getUserById(user.uid);
        if (userModel?.role == UserRole.provider) {
          appointments = await _databaseService.getProviderAppointments(user.uid);
        } else {
          appointments = await _databaseService.getClientAppointments(user.uid);
        }
        
        setState(() {
          _appointments = appointments;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des rendez-vous: $e');
    }
  }

  Future<void> _connectGoogleCalendar() async {
    try {
      await _calendarService.syncWithGoogleCalendar(_appointments.first);
      await _loadUserData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connexion à Google Calendar réussie')),
      );
    } catch (e) {
      print('Erreur lors de la connexion à Google Calendar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la connexion à Google Calendar')),
      );
    }
  }

  Future<void> _toggleAppleCalendar(bool value) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'appleCalendarEnabled': value});
        
        setState(() {
          _isAppleCalendarEnabled = value;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value 
                ? 'Export vers Apple Calendar activé' 
                : 'Export vers Apple Calendar désactivé'),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de la mise à jour des préférences: $e');
    }
  }

  Future<void> _exportToICalendar(AppointmentModel appointment) async {
    try {
      String filePath = await _calendarService.exportToICalendar(appointment);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fichier iCal créé: $filePath'),
          action: SnackBarAction(
            label: 'Ouvrir',
            onPressed: () async {
              final Uri uri = Uri.file(filePath);
              if (!await launchUrl(uri)) {
                throw Exception('Impossible d\'ouvrir le fichier');
              }
            },
          ),
        ),
      );
    } catch (e) {
      print('Erreur lors de l\'export iCal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'export iCal')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intégration de calendriers'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Synchronisation de calendriers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Google Calendar
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/google_calendar.png',
                                width: 32,
                                height: 32,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Google Calendar',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              _isGoogleCalendarConnected
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : const Icon(Icons.error_outline, color: Colors.orange),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isGoogleCalendarConnected
                                ? 'Votre compte Google Calendar est connecté.'
                                : 'Connectez votre compte Google Calendar pour synchroniser automatiquement vos rendez-vous.',
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isGoogleCalendarConnected
                                  ? null
                                  : _connectGoogleCalendar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(_isGoogleCalendarConnected
                                  ? 'Connecté'
                                  : 'Connecter Google Calendar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Apple Calendar
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/apple_calendar.png',
                                width: 32,
                                height: 32,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Apple Calendar',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: _isAppleCalendarEnabled,
                                onChanged: _toggleAppleCalendar,
                                activeColor: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Activez cette option pour exporter automatiquement vos nouveaux rendez-vous vers Apple Calendar.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Export manuel
                  const Text(
                    'Export manuel de rendez-vous',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _appointments.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Aucun rendez-vous à exporter'),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _appointments.length,
                          itemBuilder: (context, index) {
                            final appointment = _appointments[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(appointment.serviceName),
                                subtitle: Text(
                                  '${appointment.dateTime.toDate().day}/${appointment.dateTime.toDate().month}/${appointment.dateTime.toDate().year} à ${appointment.dateTime.toDate().hour}:${appointment.dateTime.toDate().minute.toString().padLeft(2, '0')}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.calendar_today),
                                  onPressed: () => _exportToICalendar(appointment),
                                  tooltip: 'Exporter au format iCal',
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}