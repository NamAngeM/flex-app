// lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';
import '../models/provider_model.dart';
import '../services/location_service.dart';
import '../services/provider_service.dart';
import '../widgets/modern_card.dart';
import '../services/app_config.dart';

class MapScreen extends StatefulWidget {
  final String? providerId;
  
  const MapScreen({Key? key, this.providerId}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  final ProviderService _providerService = ProviderService();
  
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String _errorMessage = '';
  bool _mapInitialized = false;
  
  // Position par défaut (Paris)
  final LatLng _defaultPosition = LatLng(48.8566, 2.3522);
  
  // Options de carte optimisées pour réduire l'utilisation de l'API
  final MapType _mapType = MapType.normal;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Récupérer la position actuelle
      try {
        _currentPosition = await _locationService.getCurrentLocation();
      } catch (e) {
        print('Erreur de localisation: $e');
        // Continuer avec la position par défaut
      }
      
      // Récupérer les localisations
      List<LocationModel> locations;
      if (widget.providerId != null) {
        // Si un ID de prestataire est fourni, récupérer uniquement ses localisations
        locations = await _locationService.getProviderLocations(widget.providerId!);
      } else {
        // Sinon, récupérer toutes les localisations
        locations = await _locationService.getAllLocations();
      }
      
      // Créer les marqueurs
      await _createMarkers(locations);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du chargement des données: $e';
      });
    }
  }
  
  Future<void> _createMarkers(List<LocationModel> locations) async {
    Set<Marker> markers = {};
    
    // Ajouter un marqueur pour la position actuelle si disponible
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: 'Votre position',
            snippet: 'Vous êtes ici',
          ),
        ),
      );
    }
    
    // Ajouter des marqueurs pour chaque localisation
    for (var location in locations) {
      // Récupérer les informations du prestataire si disponible
      String providerName = '';
      if (location.providerId != null && location.providerId!.isNotEmpty) {
        try {
          final provider = await _providerService.getProviderById(location.providerId!);
          if (provider != null) {
            providerName = provider.name;
          }
        } catch (e) {
          print('Erreur lors de la récupération du prestataire: $e');
        }
      }
      
      markers.add(
        Marker(
          markerId: MarkerId(location.id),
          position: LatLng(location.latitude, location.longitude),
          infoWindow: InfoWindow(
            title: location.name,
            snippet: providerName.isNotEmpty 
                ? '$providerName - ${location.address}'
                : location.address,
          ),
          onTap: () {
            _showLocationDetails(location);
          },
        ),
      );
    }
    
    setState(() {
      _markers = markers;
    });
  }
  
  void _showLocationDetails(LocationModel location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barre de préhension
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 10),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            
            // Contenu
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo
                    if (location.photoUrl != null && location.photoUrl!.isNotEmpty)
                      Container(
                        height: 150,
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(location.photoUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    
                    // Nom
                    Text(
                      location.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    SizedBox(height: 8),
                    
                    // Adresse
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location.address,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Description
                    if (location.description != null && location.description!.isNotEmpty) ...[
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(location.description!),
                      SizedBox(height: 16),
                    ],
                    
                    // Boutons d'action
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // Naviguer vers l'écran de détails du prestataire
                              if (location.providerId != null && location.providerId!.isNotEmpty) {
                                Navigator.pushNamed(
                                  context,
                                  '/provider-details',
                                  arguments: {'providerId': location.providerId},
                                );
                              }
                            },
                            icon: Icon(Icons.person),
                            label: Text('Voir le prestataire'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // Naviguer vers l'écran de prise de rendez-vous
                              if (location.providerId != null && location.providerId!.isNotEmpty) {
                                Navigator.pushNamed(
                                  context,
                                  '/new-appointment',
                                  arguments: {'providerId': location.providerId},
                                );
                              }
                            },
                            icon: Icon(Icons.calendar_today),
                            label: Text('Prendre RDV'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    // Centrer la carte sur la position actuelle ou la première localisation
    if (_currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          13,
        ),
      );
    } else if (_markers.isNotEmpty) {
      // Centrer sur le premier marqueur qui n'est pas la position actuelle
      final firstMarker = _markers.firstWhere(
        (marker) => marker.markerId.value != 'current_location',
        orElse: () => _markers.first,
      );
      
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          firstMarker.position,
          13,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carte des prestataires'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: _currentPosition != null
                            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                            : _defaultPosition,
                        zoom: 13,
                      ),
                      markers: _markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: true,
                      compassEnabled: true,
                      mapType: _mapType,
                      // Limiter le niveau de zoom pour réduire le détail et les appels API
                      minMaxZoomPreference: MinMaxZoomPreference(5, 16),
                      // Désactiver les fonctionnalités qui consomment plus d'appels API
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                    ),
                    
                    // Bouton pour recentrer sur la position actuelle
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: FloatingActionButton(
                        heroTag: 'locate',
                        onPressed: () {
                          if (_currentPosition != null && _mapController != null) {
                            _mapController!.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                15,
                              ),
                            );
                          }
                        },
                        child: Icon(Icons.my_location),
                      ),
                    ),
                  ],
                ),
    );
  }
}