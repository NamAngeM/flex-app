import 'package:flutter/material.dart';

class WeatherWidget extends StatelessWidget {
  final Map<String, dynamic> weatherData;

  const WeatherWidget({Key? key, required this.weatherData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final temp = weatherData['temperature'] ?? 0;
    final windSpeed = weatherData['windSpeed'] ?? 0;
    final windDirection = weatherData['windDirection'] ?? 0;
    final condition = weatherData['condition'] ?? 'unknown';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.blue[800],
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$temp°C',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getConditionText(condition),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                _getWeatherIcon(condition),
              ],
            ),
            SizedBox(height: 20),
            Divider(color: Colors.white.withOpacity(0.3)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherDetail(
                  Icons.air,
                  '$windSpeed km/h',
                  'Vent',
                ),
                _buildWeatherDetail(
                  Icons.explore,
                  _getDirectionText(windDirection),
                  'Direction',
                ),
                _buildWeatherDetail(
                  Icons.waves,
                  _getWindQualityText(windSpeed),
                  'Qualité',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _getWeatherIcon(String condition) {
    IconData iconData;
    double size = 60;
    
    switch (condition.toLowerCase()) {
      case 'clear':
        iconData = Icons.wb_sunny;
        break;
      case 'cloudy':
        iconData = Icons.cloud;
        break;
      case 'rainy':
        iconData = Icons.grain;
        break;
      case 'stormy':
        iconData = Icons.flash_on;
        break;
      default:
        iconData = Icons.wb_sunny_outlined;
    }
    
    return Icon(
      iconData,
      color: Colors.white,
      size: size,
    );
  }

  String _getConditionText(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return 'Ensoleillé';
      case 'cloudy':
        return 'Nuageux';
      case 'rainy':
        return 'Pluvieux';
      case 'stormy':
        return 'Orageux';
      default:
        return 'Inconnu';
    }
  }

  String _getDirectionText(int direction) {
    if (direction >= 337.5 || direction < 22.5) return 'N';
    if (direction >= 22.5 && direction < 67.5) return 'NE';
    if (direction >= 67.5 && direction < 112.5) return 'E';
    if (direction >= 112.5 && direction < 157.5) return 'SE';
    if (direction >= 157.5 && direction < 202.5) return 'S';
    if (direction >= 202.5 && direction < 247.5) return 'SO';
    if (direction >= 247.5 && direction < 292.5) return 'O';
    if (direction >= 292.5 && direction < 337.5) return 'NO';
    return 'N/A';
  }

  String _getWindQualityText(double windSpeed) {
    if (windSpeed < 10) return 'Faible';
    if (windSpeed < 20) return 'Modéré';
    if (windSpeed < 30) return 'Bon';
    if (windSpeed < 40) return 'Excellent';
    return 'Extrême';
  }
}