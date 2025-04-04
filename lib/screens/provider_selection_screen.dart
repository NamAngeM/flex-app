// lib/screens/provider_selection_screen.dart
import 'package:flutter/material.dart';
import '../models/provider_model.dart';
import '../models/service_model.dart';
import '../services/provider_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/gradient_button.dart';

class ProviderSelectionScreen extends StatefulWidget {
  final ServiceModel? initialService;

  const ProviderSelectionScreen({Key? key, this.initialService}) : super(key: key);

  @override
  _ProviderSelectionScreenState createState() => _ProviderSelectionScreenState();
}

class _ProviderSelectionScreenState extends State<ProviderSelectionScreen> {
  final ProviderService _providerService = ProviderService();
  List<ProviderModel> _providers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.initialService != null) {
        // Charger les prestataires associés au service
        final providers = await _providerService
            .getProvidersByService(widget.initialService!.id)
            .first;
        setState(() {
          _providers = providers;
          _isLoading = false;
        });
      } else {
        // Charger tous les prestataires
        final providers = await _providerService.getProviders().first;
        setState(() {
          _providers = providers;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des prestataires: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchProviders(String query) async {
    if (query.isEmpty) {
      _loadProviders();
      return;
    }

    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    try {
      final results = await _providerService.searchProviders(query).first;
      setState(() {
        _providers = results;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors de la recherche de prestataires: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Sélectionner un prestataire'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barre de recherche avec design moderne
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radius_l),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un prestataire...',
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius_l),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: theme.colorScheme.primary),
                        onPressed: () {
                          _searchController.clear();
                          _searchProviders('');
                        },
                      )
                    : null,
              ),
              onChanged: _searchProviders,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          
          // Bannière d'information sur le service sélectionné
          if (widget.initialService != null)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ModernCard(
                elevation: AppTheme.elevation_xs,
                borderRadius: AppTheme.radius_m,
                padding: EdgeInsets.all(16),
                backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.05),
                    theme.colorScheme.primary.withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service sélectionné',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary.withOpacity(0.7),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            widget.initialService!.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
          // Liste des prestataires
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : _providers.isEmpty
                    ? _buildEmptyState(theme)
                    : ListView.builder(
                        padding: EdgeInsets.all(12),
                        itemCount: _providers.length,
                        itemBuilder: (context, index) {
                          final provider = _providers[index];
                          return ProviderCard(
                            provider: provider,
                            onTap: () {
                              Navigator.pop(context, provider);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'Aucun prestataire disponible'
                : 'Aucun prestataire trouvé pour "$_searchQuery"',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 24),
          if (_searchQuery.isNotEmpty)
            GradientButton(
              text: 'Voir tous les prestataires',
              onPressed: () {
                _searchController.clear();
                _searchProviders('');
              },
              icon: Icons.refresh,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
        ],
      ),
    );
  }
}

class ProviderCard extends StatelessWidget {
  final ProviderModel provider;
  final VoidCallback onTap;

  const ProviderCard({
    Key? key,
    required this.provider,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ModernCard(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: AppTheme.elevation_s,
      borderRadius: AppTheme.radius_m,
      onTap: () {
        // Afficher une boîte de dialogue avec deux options
        showModalBottomSheet(
          context: context,
          builder: (context) => Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.check_circle, color: theme.colorScheme.primary),
                  title: Text('Sélectionner ce prestataire'),
                  onTap: () {
                    Navigator.pop(context); // Fermer la boîte de dialogue
                    onTap(); // Appeler la fonction onTap d'origine
                  },
                ),
                ListTile(
                  leading: Icon(Icons.info, color: theme.colorScheme.secondary),
                  title: Text('Voir les détails'),
                  onTap: () {
                    Navigator.pop(context); // Fermer la boîte de dialogue
                    Navigator.pushNamed(
                      context,
                      '/provider-details',
                      arguments: {'providerId': provider.id},
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.map, color: Colors.green),
                  title: Text('Voir sur la carte'),
                  onTap: () {
                    Navigator.pop(context); // Fermer la boîte de dialogue
                    Navigator.pushNamed(
                      context,
                      '/provider-map',
                      arguments: {'providerId': provider.id},
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      enableHoverEffect: true,
      backgroundColor: theme.colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar du prestataire
            Hero(
              tag: 'provider-avatar-${provider.id}',
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: provider.photoUrl != null && provider.photoUrl!.isNotEmpty
                      ? Image.network(
                          provider.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                            Container(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              child: Icon(
                                Icons.person,
                                size: 35,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                        )
                      : Container(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          child: Icon(
                            Icons.person,
                            size: 35,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(width: 16),
            
            // Informations du prestataire
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  if (provider.specialties != null &&
                      provider.specialties!.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: provider.specialties!.take(2).map((specialty) {
                        return Chip(
                          label: Text(
                            specialty,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                          backgroundColor: theme.colorScheme.primary,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 18,
                        color: Colors.amber,
                      ),
                      SizedBox(width: 4),
                      Text(
                        provider.rating?.toStringAsFixed(1) ?? 'N/A',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (provider.rating != null)
                        Text(
                          ' (${(provider.rating! * 20).toInt()} avis)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Flèche de navigation
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}