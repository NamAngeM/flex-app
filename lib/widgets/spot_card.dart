import 'package:flutter/material.dart';

class SpotCard extends StatelessWidget {
  final Map<String, dynamic> spot;

  const SpotCard({Key? key, required this.spot}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image du spot
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              spot['imageUrl'] ?? 'https://via.placeholder.com/400x200?text=Spot+de+Windsurf',
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom et notation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      spot['name'] ?? 'Spot inconnu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        SizedBox(width: 4),
                        Text(
                          '${spot['rating'] ?? 0.0}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8),
                
                // Localisation
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.grey, size: 16),
                    SizedBox(width: 4),
                    Text(
                      spot['location'] ?? 'Emplacement inconnu',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                
                // Conditions
                Row(
                  children: [
                    _buildConditionChip(
                      Icons.air,
                      '${spot['windSpeed'] ?? 0} km/h',
                    ),
                    SizedBox(width: 8),
                    _buildConditionChip(
                      Icons.waves,
                      '${spot['waveHeight'] ?? 0} m',
                    ),
                    SizedBox(width: 8),
                    _buildConditionChip(
                      Icons.people,
                      '${spot['crowdLevel'] ?? 'Faible'}',
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Bouton pour voir plus
                ElevatedButton(
                  onPressed: () {
                    // Navigation vers les détails du spot
                    Navigator.pushNamed(
                      context,
                      '/spot-details',
                      arguments: spot,
                    );
                  },
                  child: Text('Voir les détails'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue[800]),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}