// lib/screens/categories_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import '../theme/app_theme.dart';
import 'category_services_screen.dart';

class CategoriesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final categoryService = Provider.of<CategoryService>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Catégories'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: StreamBuilder<List<CategoryModel>>(
        stream: categoryService.getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            print('Erreur dans StreamBuilder: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Erreur lors du chargement des catégories',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Force refresh
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => CategoriesScreen()),
                      );
                    },
                    child: Text('Réessayer'),
                  ),
                ],
              ),
            );
          }
          
          final categories = snapshot.data ?? [];
          
          if (categories.isEmpty) {
            return Center(
              child: Text('Aucune catégorie disponible'),
            );
          }
          
          return GridView.builder(
            padding: EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(context, category);
            },
          );
        },
      ),
    );
  }
  
  Widget _buildCategoryCard(BuildContext context, CategoryModel category) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
              CategoryServicesScreen(
                arguments: {
                  'categoryId': category.id,
                  'categoryName': category.name,
                },
              ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              var begin = Offset(1.0, 0.0);
              var end = Offset.zero;
              var curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
        );
      },
      child: Hero(
        tag: 'category_${category.id}',
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    image: category.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(category.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: category.imageUrl == null
                        ? AppTheme.primaryColor.withOpacity(0.2)
                        : null,
                  ),
                  child: category.imageUrl == null
                      ? Center(
                          child: Icon(
                            _getIconData(category.iconName),
                            size: 48,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : null,
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        category.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${category.serviceCount} services',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'medical_services':
        return Icons.medical_services;
      case 'spa':
        return Icons.spa;
      case 'school':
        return Icons.school;
      case 'business':
        return Icons.business;
      case 'self_improvement':
        return Icons.self_improvement;
      default:
        return Icons.category;
    }
  }
}