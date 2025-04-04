// lib/services/appointment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/appointment_model.dart';
import '../services/auth_service.dart';
import '../services/app_config.dart';
import '../services/dev_config.dart';
import '../services/notification_service.dart';
import '../services/availability_service.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final AvailabilityService _availabilityService = AvailabilityService();
  final String _collection = 'appointments';
  final bool _devMode = AppConfig().isDevMode();
  
  // Contrôleur de stream pour les rendez-vous fictifs
  static StreamController<List<AppointmentModel>>? _mockAppointmentsController;
  
  // Liste des rendez-vous fictifs en mémoire
  static List<AppointmentModel>? _cachedMockAppointments;
  
  // Récupérer tous les rendez-vous de l'utilisateur
  Stream<List<AppointmentModel>> getUserAppointments([String? userId]) {
    if (_devMode) {
      // Initialiser le contrôleur de stream s'il n'existe pas déjà
      _mockAppointmentsController ??= StreamController<List<AppointmentModel>>.broadcast();
      
      // Initialiser la liste en cache si elle n'existe pas déjà
      _cachedMockAppointments ??= _createMockAppointments();
      
      // Vérifier que tous les rendez-vous ont un ID valide
      for (var i = 0; i < _cachedMockAppointments!.length; i++) {
        if (_cachedMockAppointments![i].id.isEmpty) {
          DevConfig().log('ATTENTION: Rendez-vous sans ID détecté, ajout d\'un ID');
          // Créer une copie du rendez-vous avec un ID valide
          final appointment = _cachedMockAppointments![i];
          _cachedMockAppointments![i] = AppointmentModel(
            id: 'mock-appointment-$i',
            clientId: appointment.clientId,
            providerId: appointment.providerId,
            serviceId: appointment.serviceId,
            dateTime: appointment.dateTime,
            durationMinutes: appointment.durationMinutes,
            status: appointment.status,
            notes: appointment.notes,
            createdAt: appointment.createdAt,
          );
        }
      }
      
      // Ajouter les données initiales au stream
      _mockAppointmentsController!.add(_cachedMockAppointments!);
      
      // Log pour le débogage
      DevConfig().log('Rendez-vous envoyés au stream: ${_cachedMockAppointments!.length}');
      DevConfig().log('IDs des rendez-vous: ${_cachedMockAppointments!.map((a) => a.id).toList()}');
      
      return _mockAppointmentsController!.stream;
    }
    
    // En mode production, utiliser l'ID de l'utilisateur connecté si aucun ID n'est fourni
    if (userId == null || userId.isEmpty) {
      return _authService.getCurrentUser().asStream().asyncExpand((user) {
        if (user == null) {
          DevConfig().log('Aucun utilisateur connecté');
          return Stream.value(<AppointmentModel>[]);
        }
        
        DevConfig().log('Récupération des rendez-vous pour l\'utilisateur: ${user.uid}');
        return _firestore
            .collection(_collection)
            .where('clientId', isEqualTo: user.uid)
            .orderBy('dateTime', descending: false)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => AppointmentModel.fromFirestore(doc))
                .toList())
            .asBroadcastStream();
      });
    }
    
    // Si un ID est fourni, l'utiliser directement
    DevConfig().log('Récupération des rendez-vous pour l\'utilisateur: $userId');
    return _firestore
        .collection(_collection)
        .where('clientId', isEqualTo: userId)
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromFirestore(doc))
            .toList())
        .asBroadcastStream();
  }
  
  // Récupérer les rendez-vous à venir de l'utilisateur
  Future<List<AppointmentModel>> getUpcomingAppointments(String userId) async {
    if (_devMode) {
      // Retourner des données simulées filtrées
      final now = DateTime.now();
      return _getMockAppointments()
          .where((appointment) => appointment.dateTime.isAfter(now))
          .toList();
    }
    
    if (userId.isEmpty) {
      return [];
    }
    
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection(_collection)
        .where('clientId', isEqualTo: userId)
        .where('dateTime', isGreaterThanOrEqualTo: now)
        .orderBy('dateTime', descending: false)
        .get();
        
    return snapshot.docs
        .map((doc) => AppointmentModel.fromFirestore(doc))
        .toList();
  }
  
  // Créer un nouveau rendez-vous
  Future<AppointmentModel> createAppointment({required Map<String, dynamic> appointmentData}) async {
    if (_devMode) {
      // Simuler la création d'un rendez-vous
      DevConfig().log('Création d\'un rendez-vous simulé: $appointmentData');
      await Future.delayed(Duration(milliseconds: 500));
      
      // Créer un rendez-vous fictif avec les données fournies
      final now = DateTime.now();
      final appointmentId = 'mock-appointment-${now.millisecondsSinceEpoch}';
      final userId = 'client-test-id';
      
      // Créer le modèle d'appointment
      final appointment = AppointmentModel(
        id: appointmentId,
        clientId: userId,
        providerId: appointmentData['providerId'] ?? 'provider-test-id',
        serviceId: appointmentData['serviceId'] ?? 'service-test-id',
        dateTime: appointmentData['dateTime'] ?? now.add(Duration(days: 1)),
        durationMinutes: appointmentData['durationMinutes'] ?? 60,
        status: AppointmentStatus.confirmed,
        notes: appointmentData['notes'],
        createdAt: now,
      );
      
      // Ajouter à la liste des rendez-vous fictifs
      _cachedMockAppointments ??= _createMockAppointments();
      _cachedMockAppointments!.add(appointment);
      
      // Mettre à jour le stream
      if (_mockAppointmentsController != null) {
        _mockAppointmentsController!.add(_cachedMockAppointments!);
      }
      
      // Simuler l'envoi d'une notification de confirmation
      DevConfig().log('Envoi d\'une notification de confirmation pour le rendez-vous: $appointmentId');
      
      return appointment;
    }
    
    final user = await _authService.getCurrentUser();
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }
    
    // Vérifier que le créneau est disponible
    final isAvailable = await _availabilityService.isTimeSlotAvailable(
      providerId: appointmentData['providerId'],
      dateTime: appointmentData['dateTime'],
      serviceDuration: appointmentData['durationMinutes'],
    );
    
    if (!isAvailable) {
      throw Exception('Ce créneau n\'est plus disponible');
    }
    
    // Ajouter l'ID du client et le statut initial
    final completeData = {
      ...appointmentData,
      'clientId': user.uid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };
    
    // Ajouter le document et récupérer la référence
    final docRef = await _firestore.collection(_collection).add(completeData);
    
    // Récupérer le document créé
    final docSnapshot = await docRef.get();
    
    // Créer le modèle d'appointment
    final appointment = AppointmentModel.fromFirestore(docSnapshot);
    
    // Envoyer une notification de confirmation
    try {
      // Récupérer les informations du service et du prestataire
      final serviceDoc = await _firestore.collection('services').doc(appointment.serviceId).get();
      final providerDoc = await _firestore.collection('providers').doc(appointment.providerId).get();
      
      String serviceName = 'Service';
      String providerName = 'Prestataire';
      
      if (serviceDoc.exists) {
        serviceName = serviceDoc.data()?['name'] ?? 'Service';
      }
      
      if (providerDoc.exists) {
        providerName = providerDoc.data()?['name'] ?? 'Prestataire';
      }
      
      // Envoyer la notification
      await _notificationService.sendAppointmentConfirmation(
        user.uid,
        appointment.id,
        serviceName,
        providerName,
        appointment.dateTime,
      );
    } catch (e) {
      print('Erreur lors de l\'envoi de la notification: $e');
      // Ne pas bloquer la création du rendez-vous si la notification échoue
    }
    
    return appointment;
  }
  
  // Annuler un rendez-vous
  Future<void> cancelAppointment(String appointmentId) async {
    if (_devMode) {
      // Simuler l'annulation d'un rendez-vous
      DevConfig().log('Annulation du rendez-vous simulé: $appointmentId');
      await Future.delayed(Duration(milliseconds: 500));
      
      // Mettre à jour le statut dans la liste des rendez-vous fictifs
      _cachedMockAppointments ??= _createMockAppointments();
      
      final index = _cachedMockAppointments!.indexWhere((a) => a.id == appointmentId);
      if (index >= 0) {
        final appointment = _cachedMockAppointments![index];
        _cachedMockAppointments![index] = appointment.copyWith(status: AppointmentStatus.cancelled);
        
        // Mettre à jour le stream
        if (_mockAppointmentsController != null) {
          _mockAppointmentsController!.add(_cachedMockAppointments!);
        }
        
        // Simuler l'annulation des rappels
        DevConfig().log('Annulation des rappels pour le rendez-vous: $appointmentId');
      }
      
      return;
    }
    
    final user = await _authService.getCurrentUser();
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }
    
    // Vérifier que le rendez-vous appartient à l'utilisateur courant
    final doc = await _firestore.collection(_collection).doc(appointmentId).get();
    if (!doc.exists || doc.get('clientId') != user.uid) {
      throw Exception('Rendez-vous non trouvé ou non autorisé');
    }
    
    // Mettre à jour le statut du rendez-vous
    await _firestore.collection(_collection).doc(appointmentId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Annuler les rappels pour ce rendez-vous
    try {
      await _notificationService.cancelAppointmentReminders(appointmentId);
      
      // Envoyer une notification d'annulation
      await _notificationService.sendNotificationToUser(
        user.uid,
        'Rendez-vous annulé',
        'Votre rendez-vous a été annulé avec succès.',
        data: {'type': 'appointment_cancelled', 'appointmentId': appointmentId},
      );
    } catch (e) {
      print('Erreur lors de l\'annulation des rappels: $e');
      // Ne pas bloquer l'annulation du rendez-vous si l'annulation des rappels échoue
    }
  }
  
  // Mettre à jour le statut d'un rendez-vous
  Future<void> updateAppointmentStatus(String appointmentId, AppointmentStatus status) async {
    // Afficher l'ID du rendez-vous pour le débogage
    DevConfig().log('Mise à jour du statut demandée pour le rendez-vous: $appointmentId -> $status');
    
    if (appointmentId.isEmpty) {
      DevConfig().log('ERREUR: ID du rendez-vous vide');
      throw Exception('ID du rendez-vous vide');
    }
    
    if (_devMode) {
      // Simuler la mise à jour du statut
      DevConfig().log('Mise à jour du statut du rendez-vous simulé: $appointmentId -> $status');
      await Future.delayed(Duration(milliseconds: 500));
      
      // En mode développement, nous devons émettre un nouvel événement dans le stream
      // pour que les écouteurs soient notifiés du changement de statut
      // Cela simule le comportement de Firestore qui émet automatiquement des événements
      // lorsque les données sont modifiées
      _mockUpdateAppointmentStatus(appointmentId, status);
      return;
    }
    
    final user = await _authService.getCurrentUser();
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }
    
    // Vérifier que le rendez-vous existe
    final doc = await _firestore.collection(_collection).doc(appointmentId).get();
    if (!doc.exists) {
      throw Exception('Rendez-vous non trouvé');
    }
    
    // Mettre à jour le statut du rendez-vous
    await _firestore.collection(_collection).doc(appointmentId).update({
      'status': status.toString().split('.').last,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Méthode privée pour mettre à jour le statut d'un rendez-vous fictif en mode développement
  void _mockUpdateAppointmentStatus(String appointmentId, AppointmentStatus status) {
    // Cette méthode est appelée uniquement en mode développement
    // Elle permet de simuler la mise à jour du statut d'un rendez-vous
    // et de notifier les écouteurs du stream
    
    // Afficher l'ID du rendez-vous pour le débogage
    DevConfig().log('Recherche du rendez-vous avec ID: $appointmentId');
    
    // Initialiser la liste en cache si elle n'existe pas déjà
    _cachedMockAppointments ??= _createMockAppointments();
    
    // Afficher tous les IDs disponibles pour le débogage
    DevConfig().log('IDs disponibles: ${_cachedMockAppointments!.map((a) => a.id).toList()}');
    
    // Trouver le rendez-vous à mettre à jour
    final index = _cachedMockAppointments!.indexWhere((appointment) => appointment.id == appointmentId);
    
    if (index != -1) {
      // Créer un nouveau rendez-vous avec le statut mis à jour
      final updatedAppointment = AppointmentModel(
        id: _cachedMockAppointments![index].id,
        clientId: _cachedMockAppointments![index].clientId,
        providerId: _cachedMockAppointments![index].providerId,
        serviceId: _cachedMockAppointments![index].serviceId,
        dateTime: _cachedMockAppointments![index].dateTime,
        durationMinutes: _cachedMockAppointments![index].durationMinutes,
        status: status,
        notes: _cachedMockAppointments![index].notes,
        createdAt: _cachedMockAppointments![index].createdAt,
      );
      
      // Mettre à jour la liste en cache
      _cachedMockAppointments![index] = updatedAppointment;
      
      // Initialiser le contrôleur de stream s'il n'existe pas déjà
      _mockAppointmentsController ??= StreamController<List<AppointmentModel>>.broadcast();
      
      // Émettre un nouvel événement dans le stream avec la liste mise à jour
      // Cela notifiera tous les écouteurs du stream
      _mockAppointmentsController!.add(_cachedMockAppointments!);
      
      // Afficher un message de débogage
      DevConfig().log('Rendez-vous mis à jour: ${appointmentId} -> ${status.toString().split('.').last}');
    } else {
      DevConfig().log('Rendez-vous non trouvé: $appointmentId');
    }
  }
  
  // Données fictives pour le mode développement
  List<AppointmentModel> _getMockAppointments() {
    // Retourner la liste en cache si elle existe
    if (_cachedMockAppointments != null) {
      return _cachedMockAppointments!;
    }
    
    // Sinon, créer une nouvelle liste
    _cachedMockAppointments = _createMockAppointments();
    return _cachedMockAppointments!;
  }
  
  // Créer une nouvelle liste de rendez-vous fictifs
  List<AppointmentModel> _createMockAppointments() {
    final now = DateTime.now();
    
    // Afficher un message pour le débogage
    DevConfig().log('Création de rendez-vous fictifs');
    
    final appointments = [
      AppointmentModel(
        id: '1',  // S'assurer que l'ID est défini
        clientId: 'client-test-id',
        providerId: 'provider-test-id',
        serviceId: '1',
        dateTime: now.add(Duration(days: 2, hours: 10)),
        durationMinutes: 60,
        status: AppointmentStatus.confirmed,
        notes: 'Rendez-vous de test confirmé',
      ),
      AppointmentModel(
        id: '2',  // S'assurer que l'ID est défini
        clientId: 'client-test-id',
        providerId: 'provider-test-id',
        serviceId: '2',
        dateTime: now.add(Duration(days: 5, hours: 14)),
        durationMinutes: 90,
        status: AppointmentStatus.pending,
        notes: 'Rendez-vous de test en attente',
      ),
      AppointmentModel(
        id: '3',  // S'assurer que l'ID est défini
        clientId: 'client-test-id',
        providerId: 'provider-test-id',
        serviceId: '3',
        dateTime: now.subtract(Duration(days: 3, hours: 9)),
        durationMinutes: 45,
        status: AppointmentStatus.completed,
        notes: 'Rendez-vous de test terminé',
      ),
      AppointmentModel(
        id: '4',  // S'assurer que l'ID est défini
        clientId: 'client-test-id',
        providerId: 'provider-test-id',
        serviceId: '4',
        dateTime: now.subtract(Duration(days: 1, hours: 11)),
        durationMinutes: 30,
        status: AppointmentStatus.cancelled,
        notes: 'Rendez-vous de test annulé',
      ),
    ];
    
    // Vérifier que tous les IDs sont définis
    for (var appointment in appointments) {
      if (appointment.id.isEmpty) {
        DevConfig().log('ATTENTION: Un rendez-vous fictif a un ID vide');
      }
    }
    
    DevConfig().log('Rendez-vous fictifs créés: ${appointments.length}');
    DevConfig().log('IDs: ${appointments.map((a) => a.id).toList()}');
    
    return appointments;
  }
  
  // Fermer le contrôleur de stream
  void dispose() {
    if (_mockAppointmentsController != null) {
      _mockAppointmentsController!.close();
      _mockAppointmentsController = null;
    }
    
    // Réinitialiser la liste en cache
    _cachedMockAppointments = null;
  }
}