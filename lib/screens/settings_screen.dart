// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  bool _emailNotifications = true;
  bool _locationServices = true;
  String _language = 'Français';
  
  final List<String> _availableLanguages = [
    'Français',
    'English',
    'Español',
    'Deutsch',
    'Italiano',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paramètres'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Apparence
          _buildSectionHeader('Apparence'),
          SwitchListTile(
            title: Text('Mode sombre'),
            subtitle: Text('Activer le thème sombre'),
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
              // Implémenter le changement de thème
            },
            secondary: Icon(Icons.brightness_4),
          ),
          _buildDivider(),
          
          // Notifications
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            title: Text('Notifications push'),
            subtitle: Text('Recevoir des notifications sur votre appareil'),
            value: _notifications,
            onChanged: (value) {
              setState(() {
                _notifications = value;
              });
            },
            secondary: Icon(Icons.notifications),
          ),
          SwitchListTile(
            title: Text('Notifications par email'),
            subtitle: Text('Recevoir des notifications par email'),
            value: _emailNotifications,
            onChanged: (value) {
              setState(() {
                _emailNotifications = value;
              });
            },
            secondary: Icon(Icons.email),
          ),
          _buildDivider(),
          
          // Confidentialité
          _buildSectionHeader('Confidentialité'),
          SwitchListTile(
            title: Text('Services de localisation'),
            subtitle: Text('Permettre à l\'application d\'accéder à votre position'),
            value: _locationServices,
            onChanged: (value) {
              setState(() {
                _locationServices = value;
              });
            },
            secondary: Icon(Icons.location_on),
          ),
          ListTile(
            title: Text('Politique de confidentialité'),
            leading: Icon(Icons.security),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Naviguer vers la politique de confidentialité
            },
          ),
          ListTile(
            title: Text('Conditions d\'utilisation'),
            leading: Icon(Icons.description),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Naviguer vers les conditions d'utilisation
            },
          ),
          _buildDivider(),
          
          // Langue
          _buildSectionHeader('Langue'),
          ListTile(
            title: Text('Langue de l\'application'),
            subtitle: Text(_language),
            leading: Icon(Icons.language),
            trailing: Icon(Icons.arrow_drop_down),
            onTap: () {
              _showLanguageDialog();
            },
          ),
          _buildDivider(),
          
          // Compte
          _buildSectionHeader('Compte'),
          ListTile(
            title: Text('Modifier le profil'),
            leading: Icon(Icons.person),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            title: Text('Changer le mot de passe'),
            leading: Icon(Icons.lock),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Naviguer vers la page de changement de mot de passe
            },
          ),
          ListTile(
            title: Text('Déconnexion'),
            leading: Icon(Icons.exit_to_app),
            onTap: () async {
              // Déconnexion
              await context.read<AuthService>().signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
          ListTile(
            title: Text(
              'Supprimer le compte',
              style: TextStyle(color: Colors.red),
            ),
            leading: Icon(Icons.delete_forever, color: Colors.red),
            onTap: () {
              _showDeleteAccountDialog();
            },
          ),
          _buildDivider(),
          
          // À propos
          _buildSectionHeader('À propos'),
          ListTile(
            title: Text('Version de l\'application'),
            subtitle: Text('1.0.0'),
            leading: Icon(Icons.info),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
  
  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, indent: 16, endIndent: 16);
  }
  
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Choisir une langue'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _availableLanguages.map((language) {
                return ListTile(
                  title: Text(language),
                  trailing: language == _language
                      ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                      : null,
                  onTap: () {
                    setState(() {
                      _language = language;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
          ],
        );
      },
    );
  }
  
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Supprimer le compte'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible et toutes vos données seront perdues.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                // Implémenter la suppression du compte
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fonctionnalité à implémenter'),
                  ),
                );
              },
              child: Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}