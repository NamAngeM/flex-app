import 'package:flutter/material.dart';

class GuestCountSelector extends StatelessWidget {
  final int guestCount;
  final int minGuests;
  final int maxGuests;
  final ValueChanged<int> onChanged;
  final String? errorMessage;

  const GuestCountSelector({
    Key? key,
    required this.guestCount,
    this.minGuests = 1,
    this.maxGuests = 10,
    required this.onChanged,
    this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nombre de convives',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: errorMessage != null 
                  ? theme.colorScheme.error 
                  : theme.primaryColor.withOpacity(0.5),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                context,
                icon: Icons.remove,
                onPressed: guestCount > minGuests
                    ? () => onChanged(guestCount - 1)
                    : null,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 60),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$guestCount',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildActionButton(
                context,
                icon: Icons.add,
                onPressed: guestCount < maxGuests
                    ? () => onChanged(guestCount + 1)
                    : null,
              ),
            ],
          ),
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Capacité maximale : $maxGuests personnes',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
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
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            size: 24,
            color: onPressed != null
                ? theme.primaryColor
                : theme.disabledColor,
          ),
        ),
      ),
    );
  }
}