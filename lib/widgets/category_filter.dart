// lib/widgets/category_filter.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import '../theme/app_theme.dart';

class CategoryFilter extends StatelessWidget {
  final String? selectedCategoryId;
  final Function(String?) onCategorySelected;

  const CategoryFilter({
    Key? key,
    this.selectedCategoryId,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryService = Provider.of<CategoryService>(context, listen: false);
    
    return StreamBuilder<List<CategoryModel>>(
      stream: categoryService.getCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }
        
        final categories = snapshot.data ?? [];
        
        if (categories.isEmpty) {
          return SizedBox.shrink();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Filtrer par catégorie',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 8),
                itemCount: categories.length + 1, // +1 pour l'option "Toutes"
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // Option "Toutes les catégories"
                    return _buildCategoryItem(
                      context,
                      null,
                      'Toutes',
                      'category',
                      selectedCategoryId == null,
                    );
                  }
                  
                  final category = categories[index - 1];
                  return _buildCategoryItem(
                    context,
                    category.id,
                    category.name,
                    category.iconName,
                    selectedCategoryId == category.id,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildCategoryItem(
    BuildContext context,
    String? categoryId,
    String name,
    String iconName,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => onCategorySelected(categoryId),
      child: Container(
        width: 80,
        margin: EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconData(iconName),
                color: isSelected ? Colors.white : AppTheme.primaryColor,
                size: 24,
              ),
            ),
            SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primaryColor : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
      case 'category':
        return Icons.category;
      default:
        return Icons.category;
    }
  }
}