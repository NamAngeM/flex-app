// lib/screens/service_details_screen.dart
import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../services/service_service.dart';
import '../widgets/modern_card.dart';
import '../widgets/skeleton_loader.dart';
import '../theme/app_theme.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;
  
  const ServiceDetailsScreen({
    Key? key,
    required this.serviceId,
  }) : super(key: key);

  @override
  _ServiceDetailsScreenState createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final ServiceService _serviceService = ServiceService();
  
  bool _isLoading = true;
  String _errorMessage = '';
  ServiceModel? _service;
  bool _isFavorite = false;
  
  @override
  void initState() {
    super.initState();
    _loadServiceDetails();
  }
  
  Future<void> _loadServiceDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final service = await _serviceService.getServiceById(widget.serviceId);
      
      setState(() {
        _service = service;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des détails du service: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Détails du service'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SkeletonCard(
                height: 200,
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 16),
              ),
              SizedBox(height: 24),
              SkeletonText(height: 24, width: 200),
              SizedBox(height: 16),
              SkeletonText(height: 16, width: 150),
              SizedBox(height: 24),
              SkeletonText(height: 16, width: double.infinity, margin: EdgeInsets.symmetric(horizontal: 16)),
              SizedBox(height: 8),
              SkeletonText(height: 16, width: double.infinity, margin: EdgeInsets.symmetric(horizontal: 16)),
              SizedBox(height: 8),
              SkeletonText(height: 16, width: 250, margin: EdgeInsets.symmetric(horizontal: 16)),
            ],
          ),
        ),
      );
    }
    
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Détails du service'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              SizedBox(height: 16),
              Text(_errorMessage),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadServiceDetails,
                child: Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_service == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Détails du service'),
        ),
        body: Center(
          child: Text('Service non trouvé'),
        ),
      );
    }
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar avec image
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _service!.imageUrl != null && _service!.imageUrl!.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image du service
                        Image.network(
                          _service!.imageUrl!,
                          fit: BoxFit.cover,
                        ),
                        // Overlay dégradé pour une meilleure lisibilité
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                              stops: [0.6, 1.0],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: theme.colorScheme.primary,
                      child: Center(
                        child: Icon(
                          Icons.business,
                          size: 80,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.black
                ),
                onPressed: () {
                  setState(() {
                    _isFavorite = !_isFavorite;
                  });
                  // Ajouter/supprimer des favoris
                },
              ),
              IconButton(
                icon: Icon(Icons.share, color: Colors.black),
                onPressed: () {
                  // Partager le service
                },
              ),
            ],
          ),
          
          // Contenu principal
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom et fournisseur du service
                  Text(
                    _service!.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: 18,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                      SizedBox(width: 8),
                      Text(
                        _service!.providerId,
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Informations clés
                  ModernCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoItem(
                          context,
                          icon: Icons.euro,
                          label: 'Prix',
                          value: '${_service!.price.toStringAsFixed(2)}€',
                          color: theme.colorScheme.primary,
                        ),
                        _buildInfoItem(
                          context,
                          icon: Icons.schedule,
                          label: 'Durée',
                          value: '${_service!.durationMinutes} heures',
                          color: theme.colorScheme.secondary,
                        ),
                        _buildInfoItem(
                          context,
                          icon: Icons.star,
                          label: 'Note',
                          value: '4.8',
                          color: AppTheme.warningColor,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Description
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _service!.description,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Informations supplémentaires
                  Text(
                    'Informations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    icon: Icons.location_on_outlined,
                    title: 'Adresse',
                    subtitle: '123 Rue de Paris, 75001 Paris',
                  ),
                  Divider(height: 24),
                  _buildInfoRow(
                    context,
                    icon: Icons.access_time,
                    title: 'Horaires',
                    subtitle: 'Lun-Ven: 9h-18h, Sam: 10h-16h',
                  ),
                  Divider(height: 24),
                  _buildInfoRow(
                    context,
                    icon: Icons.phone_outlined,
                    title: 'Contact',
                    subtitle: '+33 1 23 45 67 89',
                  ),
                  SizedBox(height: 24),
                  
                  // Avis
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Avis clients',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Voir tous les avis
                        },
                        child: Text('Voir tout'),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  _buildReviewCard(
                    context,
                    name: 'Marie Dupont',
                    date: '15 mai 2023',
                    rating: 5,
                    comment: 'Service excellent, je recommande vivement !',
                  ),
                  SizedBox(height: 12),
                  _buildReviewCard(
                    context,
                    name: 'Jean Martin',
                    date: '2 avril 2023',
                    rating: 4,
                    comment: 'Très bon service, personnel agréable et professionnel.',
                  ),
                  SizedBox(height: 24),
                  
                  // Services similaires
                  Text(
                    'Services similaires',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 160,
                          margin: EdgeInsets.only(right: 16),
                          child: ModernCard(
                            padding: EdgeInsets.all(0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image
                                Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                    image: DecorationImage(
                                      image: NetworkImage('https://picsum.photos/200/300?random=${index + 1}'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Service similaire ${index + 1}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        '${(50 + index * 10).toDouble()}€',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 8), // Espace pour le bouton flottant
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/new-appointment',
            arguments: _service,
          );
        },
        icon: Icon(Icons.calendar_today),
        label: Text('Prendre rendez-vous'),
        backgroundColor: theme.colorScheme.primary,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
  
  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildReviewCard(
    BuildContext context, {
    required String name,
    required String date,
    required int rating,
    required String comment,
  }) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                child: Text(
                  name.substring(0, 1),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: AppTheme.warningColor,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            comment,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}