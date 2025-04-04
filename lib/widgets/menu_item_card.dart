import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/menu_item_model.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItemModel menuItem;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final bool showQuantitySelector;

  const MenuItemCard({
    Key? key,
    required this.menuItem,
    this.quantity = 0,
    required this.onQuantityChanged,
    this.showQuantitySelector = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image du plat si disponible
          if (menuItem.imageUrl != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                menuItem.imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 160,
                    color: theme.primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.restaurant,
                      size: 48,
                      color: theme.primaryColor,
                    ),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec nom et badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            menuItem.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              menuItem.category!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      priceFormat.format(menuItem.price),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),

                // Description
                ...[
                  const SizedBox(height: 8),
                  Text(
                    menuItem.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],

                // Badges diététiques
                if (menuItem.dietaryInfo.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: menuItem.dietaryInfo.map((info) {
                      return _buildDietaryBadge(context, info);
                    }).toList(),
                  ),
                ],

                // Sélecteur de quantité
                if (showQuantitySelector) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quantité',
                        style: theme.textTheme.titleMedium,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.primaryColor.withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            _buildQuantityButton(
                              context,
                              icon: Icons.remove,
                              onPressed: quantity > 0
                                  ? () => onQuantityChanged(quantity - 1)
                                  : null,
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 40),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '$quantity',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            _buildQuantityButton(
                              context,
                              icon: Icons.add,
                              onPressed: () => onQuantityChanged(quantity + 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietaryBadge(BuildContext context, String info) {
    final theme = Theme.of(context);

    // Mapping des informations diététiques en français
    final Map<String, IconData> dietaryIcons = {
      'Végétarien': Icons.eco,
      'Végan': Icons.spa,
      'Sans Gluten': Icons.do_not_disturb,
      'Épicé': Icons.whatshot,
      'Fruits de Mer': Icons.set_meal,
      'Halal': Icons.check_circle,
      'Casher': Icons.check_circle_outline,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dietaryIcons.containsKey(info))
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                dietaryIcons[info],
                size: 16,
                color: theme.primaryColor,
              ),
            ),
          Text(
            info,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(
    BuildContext context, {
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: onPressed != null ? theme.primaryColor : theme.disabledColor,
          ),
        ),
      ),
    );
  }
}
