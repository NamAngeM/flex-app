// lib/screens/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = false;
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simuler le chargement des notifications depuis une API
      await Future.delayed(Duration(seconds: 1));
      
      // Données de test
      setState(() {
        _notifications = [
          NotificationItem(
            id: '1',
            title: 'Rappel de rendez-vous',
            message: 'Vous avez un rendez-vous de coiffure demain à 14h00.',
            timestamp: DateTime.now().subtract(Duration(hours: 2)),
            type: NotificationType.appointment,
            isRead: false,
            data: {'appointmentId': 'abc123'},
          ),
          NotificationItem(
            id: '2',
            title: 'Confirmation de rendez-vous',
            message: 'Votre rendez-vous de massage a été confirmé pour le 3 mars à 10h30.',
            timestamp: DateTime.now().subtract(Duration(days: 1)),
            type: NotificationType.confirmation,
            isRead: true,
            data: {'appointmentId': 'def456'},
          ),
          NotificationItem(
            id: '3',
            title: 'Annulation de rendez-vous',
            message: 'Votre rendez-vous de manucure du 1er mars a été annulé par le prestataire.',
            timestamp: DateTime.now().subtract(Duration(days: 2)),
            type: NotificationType.cancellation,
            isRead: true,
            data: {'appointmentId': 'ghi789'},
          ),
          NotificationItem(
            id: '4',
            title: 'Nouveau message',
            message: 'Vous avez reçu un nouveau message de Salon de Beauté Élégance.',
            timestamp: DateTime.now().subtract(Duration(days: 3)),
            type: NotificationType.message,
            isRead: false,
            data: {'chatId': 'chat123'},
          ),
          NotificationItem(
            id: '5',
            title: 'Promotion spéciale',
            message: 'Profitez de 20% de réduction sur tous les services de spa ce week-end !',
            timestamp: DateTime.now().subtract(Duration(days: 4)),
            type: NotificationType.promotion,
            isRead: true,
            data: {'promoId': 'promo123'},
          ),
        ];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des notifications: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
    
    // Simuler la mise à jour dans la base de données
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Toutes les notifications ont été marquées comme lues')),
    );
  }

  Future<void> _deleteNotification(String id) async {
    setState(() {
      _notifications.removeWhere((notification) => notification.id == id);
    });
    
    // Simuler la suppression dans la base de données
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notification supprimée')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: Icon(Icons.done_all),
              tooltip: 'Marquer tout comme lu',
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationItem(notification);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Aucune notification',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Vous n\'avez pas encore de notifications',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    // Déterminer l'icône en fonction du type de notification
    IconData icon;
    Color iconColor;
    
    switch (notification.type) {
      case NotificationType.appointment:
        icon = Icons.event;
        iconColor = Colors.blue;
        break;
      case NotificationType.confirmation:
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case NotificationType.cancellation:
        icon = Icons.cancel;
        iconColor = Colors.red;
        break;
      case NotificationType.message:
        icon = Icons.message;
        iconColor = Colors.purple;
        break;
      case NotificationType.promotion:
        icon = Icons.local_offer;
        iconColor = Colors.orange;
        break;
    }
    
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteNotification(notification.id);
      },
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(notification.message),
            SizedBox(height: 4),
            Text(
              dateFormat.format(notification.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor,
                ),
              ),
        onTap: () {
          // Marquer comme lu
          if (!notification.isRead) {
            setState(() {
              notification.isRead = true;
            });
          }
          
          // Naviguer vers le détail approprié en fonction du type
          switch (notification.type) {
            case NotificationType.appointment:
            case NotificationType.confirmation:
            case NotificationType.cancellation:
              if (notification.data.containsKey('appointmentId')) {
                Navigator.pushNamed(
                  context,
                  '/appointment-details',
                  arguments: notification.data['appointmentId'],
                );
              }
              break;
            case NotificationType.message:
              if (notification.data.containsKey('chatId')) {
                Navigator.pushNamed(
                  context,
                  '/chat',
                  arguments: notification.data['chatId'],
                );
              }
              break;
            case NotificationType.promotion:
              // Naviguer vers la page de promotion
              break;
          }
        },
      ),
    );
  }
}

enum NotificationType {
  appointment,
  confirmation,
  cancellation,
  message,
  promotion,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;
  final Map<String, dynamic> data;
  
  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    required this.isRead,
    required this.data,
  });
}