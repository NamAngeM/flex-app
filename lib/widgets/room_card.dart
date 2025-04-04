import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../theme/app_theme.dart';

class RoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onTap;

  const RoomCard({
    Key? key,
    required this.room,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de la chambre
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: room.photoUrls.isNotEmpty
                  ? Image.network(
                      room.photoUrls[0],
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                    )
                  : _buildPlaceholderImage(),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom et type de chambre
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          room.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getRoomTypeText(room.type),
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    room.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  // Caractéristiques de la chambre
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _buildFeatureItem(Icons.people, '${room.maxOccupancy} personne${room.maxOccupancy > 1 ? 's' : ''}'),
                      _buildFeatureItem(Icons.bed, _getBedTypeText(room.bedType)),
                      if (room.hasAirConditioning)
                        _buildFeatureItem(Icons.ac_unit, 'Climatisation'),
                      if (room.hasTv)
                        _buildFeatureItem(Icons.wifi, 'Wi-Fi'),
                      if (room.hasMinibar)
                        _buildFeatureItem(Icons.local_bar, 'Minibar'),
                      if (room.hasSafe)
                        _buildFeatureItem(Icons.lock, 'Coffre-fort'),
                      if (room.hasBalcony)
                        _buildFeatureItem(Icons.balcony, 'Balcon'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Prix
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${room.price.toStringAsFixed(0)} €',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'par nuit',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.grey[300],
      child: Icon(
        Icons.hotel,
        size: 50,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  String _getRoomTypeText(RoomType type) {
    switch (type) {
      case RoomType.standard:
        return 'Standard';
      case RoomType.deluxe:
        return 'Deluxe';
      case RoomType.suite:
        return 'Suite';
      case RoomType.familiale:
        return 'Familiale';
      case RoomType.executive:
        return 'Executive';
      default:
        return 'Standard';
    }
  }

  String _getBedTypeText(BedType type) {
    switch (type) {
      case BedType.simple:
        return 'Lit simple';
      case BedType.double:
        return 'Lit double';
      case BedType.queen:
        return 'Lit queen';
      case BedType.king:
        return 'Lit king';
      case BedType.twin:
        return 'Lits jumeaux';
      default:
        return 'Lit simple';
    }
  }
}