// lib/screens/help_screen.dart
import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  final List<Map<String, dynamic>> helpCategories = [
    {
      'title': 'Premiers pas',
      'icon': Icons.start,
      'items': [
        'Comment créer un compte',
        'Comment compléter votre profil',
        'Navigation dans l\'application',
      ],
    },
    {
      'title': 'Réservation de rendez-vous',
      'icon': Icons.calendar_today,
      'items': [
        'Rechercher un service',
        'Choisir une date et une heure',
        'Confirmer une réservation',
        'Recevoir une confirmation',
      ],
    },
    {
      'title': 'Gestion des rendez-vous',
      'icon': Icons.event_note,
      'items': [
        'Voir vos rendez-vous à venir',
        'Modifier un rendez-vous',
        'Annuler un rendez-vous',
        'Recevoir des rappels',
      ],
    },
    {
      'title': 'Paiements',
      'icon': Icons.payment,
      'items': [
        'Méthodes de paiement acceptées',
        'Sécurité des paiements',
        'Factures et reçus',
      ],
    },
    {
      'title': 'Compte et confidentialité',
      'icon': Icons.security,
      'items': [
        'Modifier vos informations personnelles',
        'Changer votre mot de passe',
        'Paramètres de confidentialité',
        'Supprimer votre compte',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aide'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: helpCategories.length,
        itemBuilder: (context, index) {
          final category = helpCategories[index];
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              leading: Icon(
                category['icon'] as IconData,
                color: Theme.of(context).primaryColor,
              ),
              title: Text(
                category['title'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: (category['items'] as List).length,
                  itemBuilder: (context, itemIndex) {
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 4,
                      ),
                      title: Text(
                        category['items'][itemIndex] as String,
                        style: TextStyle(fontSize: 15),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Navigation vers une page d'aide détaillée
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Contenu d\'aide à implémenter'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}