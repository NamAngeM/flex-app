import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../services/service_service.dart';
import '../widgets/service_card.dart';
import '../utils/app_colors.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final String? categoryId; 
  final bool isForAppointment; 

  const SearchResultsScreen({
    Key? key,
    required this.query,
    this.categoryId, 
    this.isForAppointment = false,
  }) : super(key: key);

  @override
  _SearchResultsScreenState createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final ServiceService _serviceService = ServiceService();
  List<ServiceModel> results = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      List<ServiceModel> searchResults = [];
      
      // Toujours récupérer les données fraîches depuis Firebase
      if (widget.categoryId != null && widget.categoryId!.isNotEmpty) {
        // Si une catégorie est sélectionnée, récupérer les services de cette catégorie
        searchResults = await _serviceService.getServicesByCategory(widget.categoryId!);
        
        if (widget.query.isNotEmpty) {
          // Si une requête est également spécifiée, filtrer les résultats
          final String query = widget.query.toLowerCase();
          searchResults = searchResults
              .where((service) => 
                  service.name.toLowerCase().contains(query) || 
                  service.description.toLowerCase().contains(query))
              .toList();
        }
      } else if (widget.query.isNotEmpty) {
        // Si seulement une requête est spécifiée, rechercher dans tous les services
        searchResults = await _serviceService.searchServices(widget.query);
      } else {
        // Si aucun critère n'est spécifié, récupérer tous les services
        searchResults = await _serviceService.getServices().first;
      }

      // Si aucun résultat n'est trouvé
      if (searchResults.isEmpty) {
        print('Aucun résultat trouvé, affichage de tous les services disponibles');
        
        // Récupérer tous les services disponibles comme alternative
        final allServices = await _serviceService.getServices().first;
        
        setState(() {
          results = allServices;
          _isLoading = false;
        });
        
        // Afficher un message à l'utilisateur
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Aucun résultat trouvé pour votre recherche. Voici tous les services disponibles.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        });
      } else {
        setState(() {
          results = searchResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors de la recherche: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Une erreur est survenue lors de la recherche. Veuillez réessayer.';
      });
      
      // En cas d'erreur, essayer de charger tous les services
      try {
        final allServices = await _serviceService.getServices().first;
        setState(() {
          results = allServices;
        });
      } catch (e) {
        print('Erreur lors du chargement de tous les services: $e');
        setState(() {
          _errorMessage = 'Impossible de charger les services. Veuillez vérifier votre connexion.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Résultats de recherche'),
        backgroundColor: AppColors.primary,
        actions: [
          // Ajouter un bouton de rafraîchissement pour synchroniser manuellement
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadResults,
            tooltip: 'Actualiser les résultats',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadResults,
                        child: Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Aucun service trouvé',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Essayez avec d\'autres termes de recherche',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final service = results[index];
                        return ServiceCard(
                          service: service,
                          onTap: () {
                            if (widget.isForAppointment) {
                              // Si nous sommes en mode rendez-vous, retourner le service sélectionné
                              Navigator.pop(context, service);
                            } else {
                              // Sinon, naviguer vers l'écran de détail du service
                              Navigator.pushNamed(
                                context,
                                '/service_detail',
                                arguments: {'service': service},
                              );
                            }
                          },
                        );
                      },
                    ),
    );
  }
}