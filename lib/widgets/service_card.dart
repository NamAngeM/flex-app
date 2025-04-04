// lib/widgets/service_card.dart
import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../theme/app_theme.dart';
import 'modern_card.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;
  final bool isHorizontal;

  const ServiceCard({
    Key? key,
    required this.service,
    required this.onTap,
    this.isHorizontal = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isHorizontal) {
      return _buildHorizontalCard(context);
    }

    return Container(
      width: 180,
      child: ModernCard(
        elevation: 3,
        borderRadius: 16,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shadowColor: theme.shadowColor.withOpacity(0.15),
        onTap: onTap,
        enableHoverEffect: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec badge populaire
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    image: _buildDecorationImage(),
                  ),
                  child: service.imageUrl == null || service.imageUrl!.isEmpty
                      ? Center(
                          child: Icon(
                            Icons.business,
                            size: 40,
                            color: theme.colorScheme.primary.withOpacity(0.5),
                          ),
                        )
                      : null,
                ),
                if (service.isPopular)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.tertiary.withOpacity(0.3),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Populaire',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Contenu
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.titleMedium?.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    service.providerId,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.euro,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          SizedBox(width: 2),
                          Text(
                            '${service.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.7),
                          ),
                          SizedBox(width: 2),
                          Text(
                            '${service.duration} min',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (service.rating != null && service.rating! > 0) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < service.rating!.floor()
                                ? Icons.star
                                : (index < service.rating!
                                    ? Icons.star_half
                                    : Icons.star_border),
                            color: AppTheme.warningColor,
                            size: 16,
                          );
                        }),
                        SizedBox(width: 4),
                        Text(
                          '${service.rating}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodyMedium?.color,
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
      ),
    );
  }

  Widget _buildHorizontalCard(BuildContext context) {
    final theme = Theme.of(context);

    return ModernCard(
      elevation: 3,
      borderRadius: 16,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.symmetric(vertical: 8),
      shadowColor: theme.shadowColor.withOpacity(0.15),
      onTap: onTap,
      enableHoverEffect: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              image: _buildDecorationImage(),
            ),
            child: service.imageUrl == null || service.imageUrl!.isEmpty
                ? Center(
                    child: Icon(
                      Icons.business,
                      size: 40,
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
                  )
                : null,
          ),

          // Contenu
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          service.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.titleMedium?.color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (service.isPopular)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Populaire',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    service.providerId,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.euro,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${service.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      SizedBox(width: 16),
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${service.duration} min',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  if (service.rating != null && service.rating! > 0) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < service.rating!.floor()
                                ? Icons.star
                                : (index < service.rating!
                                    ? Icons.star_half
                                    : Icons.star_border),
                            color: AppTheme.warningColor,
                            size: 16,
                          );
                        }),
                        SizedBox(width: 4),
                        Text(
                          '${service.rating}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (service.description.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      service.description,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  DecorationImage? _buildDecorationImage() {
    if (service.imageUrl != null && service.imageUrl!.isNotEmpty) {
      return DecorationImage(
        image: NetworkImage(service.imageUrl!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }
}
