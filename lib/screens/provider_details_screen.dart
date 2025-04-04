// lib/screens/provider_details_screen.dart
import 'package:flutter/material.dart';
import '../models/provider_model.dart';
import '../services/provider_service.dart';
import '../widgets/modern_card.dart';
import '../widgets/gradient_button.dart';

class ProviderDetailsScreen extends StatefulWidget {
  final String providerId;

  const ProviderDetailsScreen({Key? key, required this.providerId})
      : super(key: key);

  @override
  _ProviderDetailsScreenState createState() => _ProviderDetailsScreenState();
}

class _ProviderDetailsScreenState extends State<ProviderDetailsScreen> {
  final ProviderService _providerService = ProviderService();
  bool _isLoading = true;
  ProviderModel? _provider;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProviderDetails();
  }

  Future<void> _loadProviderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final provider =
          await _providerService.getProviderById(widget.providerId);
      setState(() {
        _provider = provider;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des détails du prestataire: $e');
      setState(() {
        _errorMessage = 'Impossible de charger les détails du prestataire';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _provider == null
                  ? Center(child: Text('Prestataire non trouvé'))
                  : CustomScrollView(
                      slivers: [
                        // App Bar avec photo du prestataire
                        SliverAppBar(
                          expandedHeight: 200.0,
                          pinned: true,
                          flexibleSpace: FlexibleSpaceBar(
                            title: Text(
                              _provider!.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10.0,
                                    color: Colors.black.withOpacity(0.5),
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            background: _provider!.photoUrl != null &&
                                    _provider!.photoUrl!.isNotEmpty
                                ? Image.network(
                                    _provider!.photoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      color: theme.colorScheme.primary,
                                      child: Icon(
                                        Icons.person,
                                        size: 80,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: theme.colorScheme.primary,
                                    child: Icon(
                                      Icons.person,
                                      size: 80,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        // Contenu
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Note et avis
                                ModernCard(
                                  padding: EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 32,
                                      ),
                                      SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _provider!.rating
                                                    ?.toStringAsFixed(1) ??
                                                'N/A',
                                            style: theme.textTheme.headlineSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            _provider!.rating != null
                                                ? '${(_provider!.rating! * 20).toInt()} avis'
                                                : 'Aucun avis',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                      Spacer(),
                                      TextButton(
                                        onPressed: () {
                                          // Afficher tous les avis
                                        },
                                        child: Text('Voir les avis'),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 24),

                                // Spécialités
                                if (_provider!.specialties != null &&
                                    _provider!.specialties!.isNotEmpty) ...[
                                  Text(
                                    'Spécialités',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _provider!.specialties!
                                        .map((specialty) => Chip(
                                              label: Text(specialty),
                                              backgroundColor:
                                                  theme.colorScheme.primary,
                                              labelStyle: TextStyle(
                                                color:
                                                    theme.colorScheme.onPrimary,
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                  SizedBox(height: 24),
                                ],

                                // Description
                                Text(
                                  'À propos',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  _provider!.description ??
                                      'Aucune description disponible pour ce prestataire.',
                                  style: theme.textTheme.bodyMedium,
                                ),

                                SizedBox(height: 24),

                                // Boutons d'action
                                Row(
                                  children: [
                                    Expanded(
                                      child: GradientButton(
                                        text: 'Prendre rendez-vous',
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/new-appointment',
                                            arguments: {
                                              'providerId': _provider!.id,
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/provider-map',
                                            arguments: {
                                              'providerId': _provider!.id,
                                            },
                                          );
                                        },
                                        icon: Icon(Icons.map),
                                        label: Text('Voir sur la carte'),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 24),

                                // Informations de contact
                                Text(
                                  'Contact',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                ModernCard(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      if (_provider!.email.isNotEmpty)
                                        ListTile(
                                          leading: Icon(Icons.email),
                                          title: Text(_provider!.email),
                                          contentPadding: EdgeInsets.zero,
                                          onTap: () {
                                            // Ouvrir l'application email
                                          },
                                        ),
                                      if (_provider!.phoneNumber != null &&
                                          _provider!.phoneNumber!.isNotEmpty)
                                        ListTile(
                                          leading: Icon(Icons.phone),
                                          title: Text(_provider!.phoneNumber!),
                                          contentPadding: EdgeInsets.zero,
                                          onTap: () {
                                            // Ouvrir l'application téléphone
                                          },
                                        ),
                                      if (_provider!.address != null &&
                                          _provider!.address!.isNotEmpty)
                                        ListTile(
                                          leading: Icon(Icons.location_on),
                                          title: Text(_provider!.address!),
                                          contentPadding: EdgeInsets.zero,
                                          onTap: () {
                                            // Ouvrir l'application de carte
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
