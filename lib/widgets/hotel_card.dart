import 'package:flutter/material.dart';
import '../models/hotel_model.dart';
import '../theme/app_theme.dart';

class HotelCard extends StatelessWidget {
  final HotelModel hotel;
  final VoidCallback onTap;

  const HotelCard({
    Key? key,
    required this.hotel,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de l'hôtel
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                hotel.photoUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
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
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom et catégorie
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          hotel.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          hotel.getCategoryName(),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  
                  // Adresse
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hotel.address,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  
                  // Services et note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Services
                      Wrap(
                        spacing: 8,
                        children: [
                          if (hotel.hasWifi)
                            Icon(Icons.wifi, size: 18, color: Colors.grey[700]),
                          if (hotel.hasBreakfast)
                            Icon(Icons.free_breakfast, size: 18, color: Colors.grey[700]),
                          if (hotel.hasParking)
                            Icon(Icons.local_parking, size: 18, color: Colors.grey[700]),
                          if (hotel.hasPool)
                            Icon(Icons.pool, size: 18, color: Colors.grey[700]),
                        ],
                      ),
                      
                      // Note
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 18,
                            color: Colors.amber,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${hotel.rating.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 2),
                          Text(
                            '(${hotel.reviewCount})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
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
}