import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/restaurant_booking_model.dart';
import '../models/restaurant_order_model.dart';
import '../models/menu_item_model.dart';

class BookingSummaryCard extends StatelessWidget {
  final RestaurantBookingModel booking;
  final RestaurantOrderModel? order;
  final int? loyaltyPointsUsed;
  final int? loyaltyPointsEarned;
  final VoidCallback? onEditPressed;

  const BookingSummaryCard({
    Key? key,
    required this.booking,
    this.order,
    this.loyaltyPointsUsed,
    this.loyaltyPointsEarned,
    this.onEditPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec titre et bouton modifier
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Résumé de la réservation',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onEditPressed != null)
                  TextButton.icon(
                    onPressed: onEditPressed,
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier'),
                  ),
              ],
            ),
            const Divider(height: 24),

            // Détails de la réservation
            _buildInfoRow(
              context,
              'Date et heure',
              dateFormat.format(booking.dateTime),
              Icons.calendar_today,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Nombre de personnes',
              '${booking.guestCount} ${booking.guestCount > 1 ? 'personnes' : 'personne'}',
              Icons.people,
            ),
            if (booking.tableNumber != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                'Numéro de table',
                'Table ${booking.tableNumber}',
                Icons.table_restaurant,
              ),
            ],

            // Résumé de la commande si présente
            if (order != null && order!.items.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Détails de la commande',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...order!.items.map((item) => _buildOrderItem(context, item)),
              const Divider(height: 24),
              
              // Sous-total
              _buildPriceRow(
                context,
                'Sous-total',
                order!.subtotal,
              ),
              if (order!.tax > 0)
                _buildPriceRow(
                  context,
                  'TVA',
                  order!.tax,
                ),
              
              // Points de fidélité
              if (loyaltyPointsUsed != null && loyaltyPointsUsed! > 0)
                _buildPriceRow(
                  context,
                  'Réduction fidélité',
                  -(loyaltyPointsUsed! * 0.1), // Exemple : 1 point = 0.10€
                  isDiscount: true,
                ),
              
              // Total
              const SizedBox(height: 8),
              _buildPriceRow(
                context,
                'Total',
                order!.total,
                isTotal: true,
              ),
              
              // Points de fidélité gagnés
              if (loyaltyPointsEarned != null && loyaltyPointsEarned! > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Vous gagnerez ${loyaltyPointsEarned!} points de fidélité',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.primaryColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItem(BuildContext context, MenuItemModel item) {
    final theme = Theme.of(context);
    final priceFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '${item.quantity}x',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.name,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            priceFormat.format(item.price * item.quantity),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    BuildContext context,
    String label,
    double amount, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    final theme = Theme.of(context);
    final priceFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
                : theme.textTheme.bodyMedium,
          ),
          Text(
            priceFormat.format(amount),
            style: isTotal
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
                : theme.textTheme.bodyMedium?.copyWith(
                    color: isDiscount ? Colors.green : null,
                  ),
          ),
        ],
      ),
    );
  }
}