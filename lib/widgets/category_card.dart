// lib/widgets/category_card.dart
import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../utils/app_colors.dart';

class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback? onTap;
  final bool isSelected;

  const CategoryCard({
    Key? key,
    required this.category,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isSelected 
            ? BorderSide(color: Colors.white, width: 2) 
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected 
                  ? [
                      AppColors.secondary.withOpacity(0.9),
                      AppColors.primary.withOpacity(0.8),
                    ]
                  : [
                      AppColors.primary.withOpacity(0.8),
                      AppColors.secondary.withOpacity(0.9),
                    ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIconData(category.iconName),
                color: Colors.white,
                size: 36,
              ),
              SizedBox(height: 8),
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${category.serviceCount} services',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'cut':
        return Icons.content_cut;
      case 'spa':
        return Icons.spa;
      case 'face':
        return Icons.face;
      case 'fitness':
        return Icons.fitness_center;
      case 'restaurant':
        return Icons.restaurant;
      case 'school':
        return Icons.school;
      default:
        return Icons.category;
    }
  }
}