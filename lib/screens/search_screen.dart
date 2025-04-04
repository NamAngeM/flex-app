import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/service_model.dart';
import '../services/category_service.dart';
import '../utils/app_colors.dart';
import '../widgets/category_card.dart';

class SearchScreen extends StatefulWidget {
  final bool isForAppointment; // Indique si la recherche est pour un rendez-vous

  const SearchScreen({
    Key? key,
    this.isForAppointment = false,
  }) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CategoryService _categoryService = CategoryService();
  String _selectedCategoryId = '';
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _categoryService.getCategories().first;
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des catégories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _search() async {
    final String query = _searchController.text.trim();
    
    if (query.isEmpty && _selectedCategoryId.isEmpty) {
      // Afficher un message si aucun critère de recherche n'est spécifié
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez entrer un terme de recherche ou sélectionner une catégorie'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Naviguer vers l'écran des résultats de recherche
    final result = await Navigator.pushNamed(
      context,
      '/search-results',
      arguments: {
        'query': query,
        'categoryId': _selectedCategoryId, // Renommé pour cohérence
        'isForAppointment': widget.isForAppointment,
      },
    );
    
    // Si un service a été sélectionné et que nous sommes en mode rendez-vous,
    // retourner le service à l'écran précédent
    if (result != null && widget.isForAppointment) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recherche'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barre de recherche améliorée
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Rechercher un service...',
                          prefixIcon: Icon(Icons.search, color: AppColors.primary),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            // Mise à jour de l'état pour afficher/masquer le bouton clear
                          });
                        },
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Suggestions de recherche populaires
                    if (_searchController.text.isEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recherches populaires',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildSearchChip('hopital'),
                              _buildSearchChip('Universite'),
                              _buildSearchChip('Restaurant'),
                              _buildSearchChip('Hotel'),
                            ],
                          ),
                          SizedBox(height: 24),
                        ],
                      ),
                    
                    // Titre des catégories
                    Text(
                      'Catégories',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Grille des catégories
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        return CategoryCard(
                          category: _categories[index],
                          isSelected: _selectedCategoryId == _categories[index].id,
                          onTap: () async {
                            setState(() {
                              // Toggle la sélection de catégorie
                              if (_selectedCategoryId == _categories[index].id) {
                                _selectedCategoryId = '';
                              } else {
                                _selectedCategoryId = _categories[index].id;
                              }
                            });
                            
                            // Option: naviguer directement vers les résultats
                            if (_selectedCategoryId.isNotEmpty) {
                              final result = await Navigator.pushNamed(
                                context,
                                '/search-results',
                                arguments: {
                                  'query': '',
                                  'categoryId': _selectedCategoryId,
                                  'isForAppointment': widget.isForAppointment,
                                },
                              );
                              
                              if (result != null && widget.isForAppointment) {
                                Navigator.pop(context, result);
                              }
                            }
                          },
                        );
                      },
                    ),
                    SizedBox(height: 24),
                    
                    // Bouton de recherche
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _search,
                        icon: Icon(Icons.search),
                        label: Text(
                          'Rechercher',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          elevation: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  // Widget pour les suggestions de recherche
  Widget _buildSearchChip(String label) {
    return InkWell(
      onTap: () {
        setState(() {
          _searchController.text = label;
        });
        _search();
      },
      child: Chip(
        label: Text(label),
        backgroundColor: Colors.grey.shade200,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      ),
    );
  }
}