// lib/screens/category_services_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/service_model.dart';
import '../models/hotel_model.dart';
import '../services/service_service.dart';
import '../services/hotel_service.dart';
import '../widgets/service_card.dart';
import '../widgets/hotel_card.dart';
import '../theme/app_theme.dart';

class CategoryServicesScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  
  const CategoryServicesScreen({Key? key, this.arguments}) : super(key: key);
  
  @override
  _CategoryServicesScreenState createState() => _CategoryServicesScreenState();
}

class _CategoryServicesScreenState extends State<CategoryServicesScreen> {
  final HotelService _hotelService = HotelService();
  final ServiceService _serviceService = ServiceService();
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  Widget build(BuildContext context) {
    final args = widget.arguments ?? ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final categoryId = args['categoryId'] as String;
    final categoryName = args['categoryName'] as String;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _buildCategoryContent(context, categoryId, categoryName),
    );
  }
  
  Widget _buildCategoryContent(BuildContext context, String categoryId, String categoryName) {
    // Vérifier si c'est la catégorie Hôtels
    final bool isHotelCategory = categoryName.toLowerCase() == 'hôtels' || categoryId == 'cat6';
    
    if (isHotelCategory) {
      return _buildHotelsContent(context);
    } else {
      return _buildServicesContent(context, categoryId);
    }
  }
  
  Widget _buildServicesContent(BuildContext context, String categoryId) {
    return FutureBuilder<List<ServiceModel>>(
      future: _serviceService.getServicesByCategory(categoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement des services',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[700]),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: Text('Réessayer'),
                ),
              ],
            ),
          );
        }
        
        final services = snapshot.data ?? [];
        
        if (services.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'Aucun service disponible dans cette catégorie',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Retour aux catégories'),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return ServiceCard(
              service: service,
              onTap: () {
                // Navigation vers l'écran de détail du service ou de sélection du prestataire
                Navigator.pushNamed(
                  context,
                  '/provider_selection',
                  arguments: {'initialService': service},
                );
              },
            );
          },
        );
      },
    );
  }
  
  Widget _buildHotelsContent(BuildContext context) {
    return FutureBuilder<List<HotelModel>>(
      future: _hotelService.getHotels(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement des hôtels',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[700]),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: Text('Réessayer'),
                ),
              ],
            ),
          );
        }
        
        final hotels = snapshot.data ?? [];
        
        if (hotels.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'Aucun hôtel disponible pour le moment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Retour aux catégories'),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: hotels.length,
          itemBuilder: (context, index) {
            final hotel = hotels[index];
            return HotelCard(
              hotel: hotel,
              onTap: () {
                // Navigation vers l'écran de détail de l'hôtel
                Navigator.pushNamed(
                  context,
                  '/hotel_detail',
                  arguments: {'hotel': hotel},
                );
              },
            );
          },
        );
      },
    );
  }
}