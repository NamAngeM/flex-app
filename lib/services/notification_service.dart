// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialiser les notifications
  Future<void> initialize() async {
    // Demander la permission pour les notifications push
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print(
        'Statut des autorisations de notification: ${settings.authorizationStatus}');

    // Configurer les notifications locales
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Gérer la notification lorsque l'utilisateur clique dessus
        print('Notification cliquée: ${response.payload}');
      },
    );

    // Configurer les canaux de notification pour Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notifications importantes',
      description: 'Ce canal est utilisé pour les notifications importantes',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Gérer les messages reçus en arrière-plan
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Gérer les messages reçus lorsque l'application est ouverte
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
          'Message reçu pendant que l\'app est ouverte: ${message.notification?.title}');

      if (message.notification != null) {
        _showLocalNotification(
          message.notification!.title ?? 'Nouvelle notification',
          message.notification!.body ?? '',
          message.data,
        );
      }
    });

    // Gérer les messages qui ont ouvert l'application
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(
          'L\'application a été ouverte depuis une notification: ${message.notification?.title}');
      // Naviguer vers l'écran approprié en fonction des données de la notification
    });

    // Vérifier si l'application a été ouverte à partir d'une notification
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print(
          'L\'application a été lancée depuis une notification: ${initialMessage.notification?.title}');
      // Naviguer vers l'écran approprié
    }

    // Sauvegarder le token FCM pour l'utilisateur actuel
    _saveTokenToDatabase();

    // Écouter les changements de token
    _messaging.onTokenRefresh.listen((token) => _saveTokenToDatabase());
  }

  // Sauvegarder le token FCM dans Firestore
  Future<void> _saveTokenToDatabase() async {
    String? token = await _messaging.getToken();
    print('FCM Token: $token');

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    }
  }

  // Afficher une notification locale
  Future<void> _showLocalNotification(
      String title, String body, Map<String, dynamic> payload) async {
    AndroidNotificationDetails androidDetails =
        const AndroidNotificationDetails(
      'high_importance_channel',
      'Notifications importantes',
      channelDescription:
          'Ce canal est utilisé pour les notifications importantes',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      platformDetails,
      payload: payload.toString(),
    );
  }

  // Envoyer une notification à un utilisateur spécifique
  Future<void> sendNotificationToUser(String userId, String title, String body,
      {Map<String, dynamic>? data}) async {
    try {
      // Récupérer le document de l'utilisateur
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        List<dynamic> fcmTokens = userData['fcmTokens'] ?? [];

        if (fcmTokens.isNotEmpty) {
          // Créer une notification dans Firestore
          await _firestore.collection('notifications').add({
            'userId': userId,
            'title': title,
            'body': body,
            'data': data ?? {},
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

          print(
              'Notification enregistrée dans Firestore pour l\'utilisateur $userId');
        }
      }
    } catch (e) {
      print('Erreur lors de l\'envoi de la notification: $e');
    }
  }

  // Marquer une notification comme lue
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  // Récupérer les notifications d'un utilisateur
  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Supprimer une notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // Planifier un rappel de rendez-vous
  Future<void> scheduleAppointmentReminder(String appointmentId, String userId,
      String title, String body, DateTime appointmentTime) async {
    try {
      // Planifier des rappels à différents moments avant le rendez-vous
      final reminders = [
        {
          'hours': 24,
          'title': 'Rappel: Rendez-vous demain',
          'body':
              'Vous avez rendez-vous demain à ${_formatTime(appointmentTime)}'
        },
        {
          'hours': 2,
          'title': 'Rappel: Rendez-vous bientôt',
          'body': 'Votre rendez-vous est dans 2 heures'
        },
        {
          'hours': 1,
          'title': 'Rappel: Rendez-vous imminent',
          'body': 'Votre rendez-vous est dans 1 heure'
        },
      ];

      for (var reminder in reminders) {
        final notificationTime = appointmentTime
            .subtract(Duration(hours: (reminder['hours'] as num).toInt()));

        // Ne pas planifier de rappels dans le passé
        if (notificationTime.isAfter(DateTime.now())) {
          // Créer une notification dans Firestore
          await _firestore.collection('scheduledNotifications').add({
            'userId': userId,
            'appointmentId': appointmentId,
            'title': reminder['title'],
            'body': reminder['body'],
            'scheduledFor': notificationTime,
            'sent': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Planifier la notification locale
          await _scheduleLocalNotification(
            id: appointmentId.hashCode + (reminder['hours'] as num).toInt(),
            title: reminder['title'] as String,
            body: reminder['body'] as String,
            scheduledDate: notificationTime,
            payload: {'appointmentId': appointmentId, 'type': 'reminder'},
          );

          print('Rappel planifié pour $appointmentId à $notificationTime');
        }
      }
    } catch (e) {
      print('Erreur lors de la planification du rappel: $e');
    }
  }

  // Formater l'heure pour l'affichage
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Planifier une notification locale
  Future<void> _scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required Map<String, dynamic> payload,
  }) async {
    AndroidNotificationDetails androidDetails =
        const AndroidNotificationDetails(
      'appointment_reminders',
      'Rappels de rendez-vous',
      channelDescription:
          'Ce canal est utilisé pour les rappels de rendez-vous',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload.toString(),
    );
  }

  // Annuler tous les rappels pour un rendez-vous
  Future<void> cancelAppointmentReminders(String appointmentId) async {
    try {
      // Supprimer les notifications planifiées dans Firestore
      final querySnapshot = await _firestore
          .collection('scheduledNotifications')
          .where('appointmentId', isEqualTo: appointmentId)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      // Annuler les notifications locales
      await _localNotifications.cancel(appointmentId.hashCode + 24);
      await _localNotifications.cancel(appointmentId.hashCode + 2);
      await _localNotifications.cancel(appointmentId.hashCode + 1);

      print('Rappels annulés pour le rendez-vous $appointmentId');
    } catch (e) {
      print('Erreur lors de l\'annulation des rappels: $e');
    }
  }

  // Envoyer une notification de confirmation de rendez-vous
  Future<void> sendAppointmentConfirmation(String userId, String appointmentId,
      String serviceName, String providerName, DateTime appointmentTime) async {
    final title = 'Rendez-vous confirmé';
    final body =
        'Votre rendez-vous de $serviceName avec $providerName le ${_formatDate(appointmentTime)} à ${_formatTime(appointmentTime)} a été confirmé.';

    await sendNotificationToUser(userId, title, body, data: {
      'type': 'appointment_confirmation',
      'appointmentId': appointmentId,
    });

    // Planifier des rappels pour ce rendez-vous
    await scheduleAppointmentReminder(
      appointmentId,
      userId,
      'Rappel de rendez-vous',
      'Vous avez rendez-vous pour $serviceName avec $providerName',
      appointmentTime,
    );
  }

  // Formater la date pour l'affichage
  String _formatDate(DateTime dateTime) {
    final months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre'
    ];
    final days = [
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche'
    ];

    final dayOfWeek = days[dateTime.weekday - 1];
    final day = dateTime.day;
    final month = months[dateTime.month - 1];

    return '$dayOfWeek $day $month';
  }

  // Envoyer une notification de modification de rendez-vous
  Future<void> sendAppointmentUpdateNotification(
      String userId, String appointmentId, String message) async {
    await sendNotificationToUser(userId, 'Modification de rendez-vous', message,
        data: {
          'type': 'appointment_update',
          'appointmentId': appointmentId,
        });
  }

  // Envoyer une notification de rappel de rendez-vous
  Future<void> sendAppointmentReminderNotification(
      String userId, String appointmentId, String message) async {
    await sendNotificationToUser(userId, 'Rappel de rendez-vous', message,
        data: {
          'type': 'appointment_reminder',
          'appointmentId': appointmentId,
        });
  }
}

// Gestionnaire de messages en arrière-plan
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialiser Firebase si nécessaire
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('Message en arrière-plan reçu: ${message.notification?.title}');
}
