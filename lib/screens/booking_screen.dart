// lib/screens/booking_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class BookingListScreen extends StatefulWidget {
  @override
  _BookingListScreenState createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BookingService _bookingService = BookingService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthService>().currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Réservations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'À venir'),
            Tab(text: 'Historique'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BookingList(
            stream: _bookingService.getUserBookings(userId),
            isPast: false,
          ),
          _BookingList(
            stream: _bookingService.getUserBookings(userId),
            isPast: true,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _BookingList extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final bool isPast;

  const _BookingList({
    required this.stream,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Une erreur est survenue'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data!.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .where((booking) {
          final bookingDate = (booking['dateTime'] as Timestamp).toDate();
          return isPast
              ? bookingDate.isBefore(DateTime.now())
              : bookingDate.isAfter(DateTime.now());
        }).toList();

        if (bookings.isEmpty) {
          return Center(
            child: Text(
              isPast
                  ? 'Aucune réservation passée'
                  : 'Aucune réservation à venir',
            ),
          );
        }

        return ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            final bookingDate = (booking['dateTime'] as Timestamp).toDate();

            return BookingCard(
              serviceId: booking['service'],
              dateTime: bookingDate,
              status: booking['status'],
              onTap: () => Navigator.pushNamed(
                context,
                '/booking-detail',
                arguments: booking['id'],
              ),
            );
          },
        );
      },
    );
  }
}

class BookingCard extends StatelessWidget {
  final String serviceId;
  final DateTime dateTime;
  final String status;
  final VoidCallback onTap;

  const BookingCard({
    required this.serviceId,
    required this.dateTime,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('services')
                    .doc(serviceId)
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Text('Chargement...');
                  }
                  final service = snapshot.data!.data() as Map<String, dynamic>;
                  return Text(
                    service['name'],
                    style: Theme.of(context).textTheme.titleLarge,
                  );
                },
              ),
              SizedBox(height: 8),
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(dateTime),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getStatusText(status),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmé';
      case 'cancelled':
        return 'Annulé';
      default:
        return 'Inconnu';
    }
  }
}