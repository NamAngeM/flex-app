import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/hotel_booking_model.dart';
import '../models/hotel_model.dart';
import '../models/room_model.dart';
import '../theme/app_theme.dart';
import '../widgets/button_widget.dart';
import 'my_bookings_screen.dart';
import 'home_screen.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final HotelBookingModel booking;
  final HotelModel hotel;
  final RoomModel room;

  const BookingConfirmationScreen({
    Key? key,
    required this.booking,
    required this.hotel,
    required this.room,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirmation de réservation'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icône de succès
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
            ),
            SizedBox(height: 24),
            
            // Message de confirmation
            Text(
              'Votre réservation a été confirmée !',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Numéro de réservation: ${booking.id.substring(0, 8).toUpperCase()}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            
            // Détails de la réservation
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Détails de la réservation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildDetailRow('Hôtel', hotel.name),
                    _buildDetailRow('Chambre', room.name),
                    _buildDetailRow('Arrivée', dateFormat.format(booking.checkInDate)),
                    _buildDetailRow('Départ', dateFormat.format(booking.checkOutDate)),
                    _buildDetailRow('Voyageurs', '${booking.numberOfGuests} personne${booking.numberOfGuests > 1 ? 's' : ''}'),
                    _buildDetailRow('Chambres', '${booking.numberOfRooms}'),
                    _buildDetailRow('Prix total', '${booking.totalPrice.toStringAsFixed(2)} €'),
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 16),
                    Text(
                      'Informations importantes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Check-in: à partir de 14h00\nCheck-out: jusqu\'à 12h00\n\nVeuillez présenter une pièce d\'identité et la carte de crédit utilisée pour la réservation lors de votre arrivée.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (booking.specialRequests.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Text(
                        'Demandes spéciales',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        booking.specialRequests,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),
            
            // Boutons d'action
            AppButton(
              text: 'Voir mes réservations',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyBookingsScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            AppButton(
              text: 'Retour à l\'accueil',
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(),
                  ),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}