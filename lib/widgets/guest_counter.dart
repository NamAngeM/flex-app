import 'package:flutter/material.dart';

class GuestCounter extends StatelessWidget {
  final int guestCount;
  final Function(int) onChanged;
  
  const GuestCounter({
    Key? key,
    required this.guestCount,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: guestCount > 1 ? () => onChanged(guestCount - 1) : null,
        ),
        Text(
          '$guestCount',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => onChanged(guestCount + 1),
        ),
        const SizedBox(width: 8),
        Text(
          'Invités',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}