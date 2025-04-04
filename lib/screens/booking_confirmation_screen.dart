import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/hotel_booking_model.dart';
import '../services/hotel_service.dart';
import '../widgets/button_widget.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final HotelBookingModel booking;
  final String hotelName;
  final String roomName;

  const BookingConfirmationScreen({
    Key? key,
    required this.booking,
    required this.hotelName,
    required this.roomName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation de réservation'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              'Réservation confirmée !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildInfoCard(context),
            const SizedBox(height: 24),
            AppButton(
              text: 'Voir mes réservations',
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/my-bookings');
              },
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Retour à l\'accueil',
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
              isPrimary: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Hôtel', hotelName),
            const Divider(),
            _buildInfoRow('Chambre', roomName),
            const Divider(),
            _buildInfoRow(
              'Dates',
              '${_formatDate(booking.checkInDate)} - ${_formatDate(booking.checkOutDate)}',
            ),
            const Divider(),
            _buildInfoRow('Nombre de personnes', '${booking.numberOfGuests}'),
            const Divider(),
            _buildInfoRow('Nombre de chambres', '${booking.numberOfRooms}'),
            const Divider(),
            _buildInfoRow('Prix total', '${booking.totalPrice.toStringAsFixed(2)} €'),
            const Divider(),
            _buildInfoRow('Statut', 'Confirmé'),
            const Divider(),
            _buildInfoRow('Numéro de réservation', booking.id),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}