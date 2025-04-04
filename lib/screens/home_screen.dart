// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/appointment_model.dart';
import '../models/service_model.dart';
import '../models/category_model.dart';
import '../services/auth_service.dart';
import '../services/appointment_service.dart';
import '../services/service_service.dart';
import '../services/category_service.dart';
import '../services/app_config.dart';
import '../widgets/appointment_card.dart';
import '../widgets/service_card.dart';
import '../widgets/modern_card.dart';
import '../widgets/skeleton_loader.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final ServiceService _serviceService = ServiceService();
  final CategoryService _categoryService = CategoryService();
  
  bool _isLoading = true;
  String _errorMessage = '';
  List<AppointmentModel> _upcomingAppointments = [];
  List<ServiceModel> _popularServices = [];
  List<CategoryModel> _categories = [];

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
      final user = Provider.of<UserModel?>(context, listen: false);
      
      if (user != null) {
        print('Utilisateur trouvé: ${user.uid}');
        
        // Charger les rendez-vous à venir
        List<AppointmentModel> appointments = [];
        try {
          appointments = await _appointmentService.getUpcomingAppointments(user.uid);
          print('Rendez-vous chargés: ${appointments.length}');
        } catch (e) {
          print('Erreur lors du chargement des rendez-vous: $e');
          // Ne pas propager l'erreur, juste logger et continuer
        }
        
        // Charger les services populaires
        List<ServiceModel> services = [];
        try {
          services = await _serviceService.getPopularServices();
          print('Services populaires chargés: ${services.length}');
        } catch (e) {
          print('Erreur lors du chargement des services: $e');
          // Ne pas propager l'erreur, juste logger et continuer
        }
        
        // Charger les catégories avec une meilleure gestion d'erreur
        List<CategoryModel> categories = [];
        try {
          // Utiliser un timeout pour éviter de bloquer indéfiniment
          categories = await _categoryService.getCategories()
              .first
              .timeout(Duration(seconds: 5), onTimeout: () {
                print('Timeout lors du chargement des catégories, utilisation de la liste par défaut');
                return _categoryService.getMockCategories();
              });
          print('Catégories chargées: ${categories.length}');
        } catch (e) {
          print('Erreur lors du chargement des catégories: $e');
          // En cas d'erreur, utiliser les catégories fictives directement
          categories = _categoryService.getMockCategories();
          print('Utilisation des catégories fictives: ${categories.length}');
        }
        
        setState(() {
          _upcomingAppointments = appointments;
          _popularServices = services;
          _categories = categories;
          _isLoading = false;
        });
      } else {
        print('Utilisateur non connecté, tentative de récupération...');
        // Tenter de récupérer l'utilisateur de test en mode développement
        if (AppConfig().isDevMode()) {
          final AuthService authService = AuthService();
          final testUser = await authService.getCurrentUser();
          if (testUser != null) {
            print('Utilisateur de test récupéré: ${testUser.uid}');
            // Continuer avec l'utilisateur de test
            List<AppointmentModel> appointments = [];
            List<ServiceModel> services = [];
            List<CategoryModel> categories = [];
            
            try {
              categories = _categoryService.getMockCategories();
              services = await _serviceService.getPopularServices();
              appointments = await _appointmentService.getUpcomingAppointments(testUser.uid);
            } catch (e) {
              print('Erreur lors du chargement des données avec utilisateur de test: $e');
            }
            
            setState(() {
              _upcomingAppointments = appointments;
              _popularServices = services;
              _categories = categories;
              _isLoading = false;
            });
            return;
          }
        }
        
        setState(() {
          _errorMessage = 'Utilisateur non connecté';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur dans _loadData: $e');
      setState(() {
        _errorMessage = 'Erreur lors du chargement des données: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png', // Remplace par le chemin correct de ton logo
              height: 30, // Ajuste la taille selon tes besoins
            ),
            SizedBox(width: 8), // Espace entre le logo et le texte
            Text(
              'FlexiBook',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          IconButton(
            icon: Icon(Icons.person_outline),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading 
          ? _buildLoadingView() 
          : _errorMessage.isNotEmpty 
            ? _buildErrorView() 
            : _buildHomeContent(theme),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/new-appointment');
        },
        icon: Icon(Icons.add),
        label: Text('Rendez-vous rapide'),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }
  
  Widget _buildLoadingView() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          SizedBox(height: 16),
          Text(_errorMessage),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: Text('Réessayer'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHomeContent(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Bannière d'accueil
          _buildWelcomeBanner(),
          
          // Section Catégories
          _buildCategoriesSection(theme),
          
          // Section Services populaires
          _buildPopularServicesSection(),
          
          // Section Recommandés pour vous
          _buildRecommendedServicesSection(),
        ],
      ),
    );
  }
  
  // Nouvelle section de bannière d'accueil
  Widget _buildWelcomeBanner() {
    try {
      final user = Provider.of<UserModel>(context);
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour ${user.firstName ?? ""} ✌️',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Que souhaitez-vous réserver aujourd\'hui ?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Erreur lors de l\'affichage de la bannière d\'accueil: $e');
      return SizedBox.shrink();
    }
  }
  
  Widget _buildCategoriesSection(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Catégories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/categories');
                },
                child: Text('Voir tout'),
              ),
            ],
          ),
          SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildMainCategoryItem(
                context,
                icon: Icons.hotel,
                label: 'Hôtel',
                color: Colors.blue.shade100,
                iconColor: Colors.blue,
                onTap: () {
                  Navigator.pushNamed(context, '/hotels');
                },
              ),
              _buildMainCategoryItem(
                context,
                icon: Icons.restaurant,
                label: 'Restaurant',
                color: Colors.red.shade100,
                iconColor: Colors.red,
                onTap: () {
                  Navigator.pushNamed(context, '/restaurants');
                },
              ),
              _buildMainCategoryItem(
                context,
                icon: Icons.business,
                label: 'Services Pro',
                color: Colors.amber.shade100,
                iconColor: Colors.amber,
                onTap: () {
                  Navigator.pushNamed(context, '/services');
                },
              ),
              _buildMainCategoryItem(
                context,
                icon: Icons.sports,
                label: 'Sport',
                color: Colors.green.shade100,
                iconColor: Colors.green,
                onTap: () {
                  Navigator.pushNamed(context, '/sports');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMainCategoryItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 30,
              ),
            ),
            SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularServicesSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Services populaires',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/popular-services');
                },
                child: Text('Voir tout'),
              ),
            ],
          ),
          SizedBox(height: 16),
          _popularServices.isEmpty
              ? _buildEmptyServicesView('Aucun service populaire disponible')
              : SizedBox(
                  height: 250,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _popularServices.length,
                    itemBuilder: (context, index) {
                      final service = _popularServices[index];
                      return Padding(
                        padding: EdgeInsets.only(right: index < _popularServices.length - 1 ? 16 : 0),
                        child: _buildServiceCard(
                          imageUrl: service.imageUrl ?? 'assets/images/placeholder.jpg',
                          name: service.name,
                          rating: service.rating ?? 0.0,
                          reviewCount: 120, // Valeur fixe en attendant l'implémentation dans le modèle
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/service-details',
                            arguments: service.id,
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildRecommendedServicesSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommandés pour vous',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/recommended-services');
                },
                child: Text('Voir tout'),
              ),
            ],
          ),
          SizedBox(height: 16),
          _popularServices.isEmpty
              ? _buildEmptyServicesView('Aucune recommandation disponible')
              : SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _popularServices.length,
                    itemBuilder: (context, index) {
                      final service = _popularServices[index];
                      return Padding(
                        padding: EdgeInsets.only(right: index < _popularServices.length - 1 ? 16 : 0),
                        child: _buildRecommendedCard(
                          imageUrl: service.imageUrl ?? 'assets/images/placeholder.jpg',
                          name: service.name,
                          price: service.price,
                          source: 'Agoda.com',
                          onTap: () => Navigator.pushNamed(
                            context, 
                            '/service-details',
                            arguments: service.id,
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
  
  Widget _buildServiceCard({
    required String imageUrl,
    required String name,
    required double rating,
    required int reviewCount,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: _buildImageWidget(imageUrl, 140),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '${rating.toStringAsFixed(1)} ($reviewCount)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
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
  
  Widget _buildRecommendedCard({
    required String imageUrl,
    required String name,
    required double price,
    required String source,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Image avec gestion d'erreur
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildImageWidget(imageUrl, 200),
            ),
            // Overlay gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            // Price tag
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${price.toInt()} €',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            // Source
            Positioned(
              bottom: 16,
              right: 16,
              child: Text(
                source,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
            // Name
            Positioned(
              bottom: 16,
              left: 16,
              right: 100,
              child: Text(
                name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget réutilisable pour afficher les images avec gestion d'erreur
  Widget _buildImageWidget(String imageUrl, double height) {
    try {
      if (imageUrl.startsWith('http')) {
        return Image.network(
          imageUrl,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Erreur de chargement d\'image: $error');
            return _buildImageErrorWidget(height);
          },
        );
      } else {
        return Image.asset(
          imageUrl,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Erreur de chargement d\'image: $error');
            return _buildImageErrorWidget(height);
          },
        );
      }
    } catch (e) {
      print('Exception lors du chargement de l\'image: $e');
      return _buildImageErrorWidget(height);
    }
  }
  
  // Widget réutilisable pour les erreurs d'image
  Widget _buildImageErrorWidget(double height) {
    return Container(
      height: height,
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Image non disponible',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget pour afficher un message quand il n'y a pas de services
  Widget _buildEmptyServicesView(String message) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}