import 'package:flutter/material.dart';
import '../models/restaurant_table_model.dart';
import '../theme/app_theme.dart';

class TableSelectionWidget extends StatelessWidget {
  final List<RestaurantTableModel> tables;
  final RestaurantTableModel? selectedTable;
  final Function(RestaurantTableModel) onTableSelected;

  const TableSelectionWidget({
    Key? key,
    required this.tables,
    this.selectedTable,
    required this.onTableSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Liste des tables
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index];
              final isSelected = selectedTable?.id == table.id;
              
              return GestureDetector(
                onTap: () => onTableSelected(table),
                child: Container(
                  width: 120,
                  margin: EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getTableIcon(table.type),
                        size: 36,
                        color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
                      ),
                      SizedBox(height: 8),
                      Text(
                        table.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppTheme.primaryColor : Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${table.capacity} ${table.capacity > 1 ? 'personnes' : 'personne'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Détails de la table sélectionnée
        if (selectedTable != null) ...[
          SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Détails de la table',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildTableDetail(
                    Icons.chair, 
                    'Type', 
                    _getTableTypeName(selectedTable!.type),
                  ),
                  SizedBox(height: 8),
                  _buildTableDetail(
                    Icons.people, 
                    'Capacité', 
                    '${selectedTable!.capacity} ${selectedTable!.capacity > 1 ? 'personnes' : 'personne'}',
                  ),
                  SizedBox(height: 8),
                  _buildTableDetail(
                    Icons.location_on, 
                    'Emplacement', 
                    _getLocationName(selectedTable!.location),
                  ),
                  if (selectedTable!.features.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Text(
                      'Caractéristiques',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedTable!.features.entries
                          .where((entry) => entry.value == true)
                          .map((entry) => _buildFeatureChip(entry.key))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTableDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey[600],
        ),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureChip(String feature) {
    String label;
    IconData icon;
    
    switch (feature) {
      case 'window':
        label = 'Vue extérieure';
        icon = Icons.visibility;
        break;
      case 'private':
        label = 'Espace privé';
        icon = Icons.lock;
        break;
      case 'quiet':
        label = 'Zone calme';
        icon = Icons.volume_off;
        break;
      case 'accessible':
        label = 'Accessible PMR';
        icon = Icons.accessible;
        break;
      default:
        label = feature;
        icon = Icons.check_circle;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey[700],
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTableIcon(TableType type) {
    switch (type) {
      case TableType.standard:
        return Icons.table_restaurant;
      case TableType.booth:
        return Icons.weekend;
      case TableType.bar:
        return Icons.local_bar;
      case TableType.outdoor:
        return Icons.deck;
      case TableType.private:
        return Icons.meeting_room;
      default:
        return Icons.table_restaurant;
    }
  }

  String _getTableTypeName(TableType type) {
    switch (type) {
      case TableType.standard:
        return 'Standard';
      case TableType.booth:
        return 'Banquette';
      case TableType.bar:
        return 'Bar';
      case TableType.outdoor:
        return 'Terrasse';
      case TableType.private:
        return 'Salle privée';
      default:
        return 'Standard';
    }
  }

  String _getLocationName(TableLocation location) {
    switch (location) {
      case TableLocation.interieur:
        return 'Intérieur';
      case TableLocation.terrasse:
        return 'Terrasse';
      case TableLocation.salon:
        return 'Salon';
      case TableLocation.bar:
        return 'Bar';
      case TableLocation.vip:
        return 'Espace VIP';
      default:
        return 'Intérieur';
    }
  }
}