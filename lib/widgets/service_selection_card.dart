import 'package:flutter/material.dart';

class ServiceSelectionCard extends StatelessWidget {
  final String serviceName;
  final double price;
  final bool isSelected;
  final VoidCallback onTap;
  
  const ServiceSelectionCard({
    Key? key,
    required this.serviceName,
    required this.price,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                serviceName,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '+${price.toStringAsFixed(2)} €',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}