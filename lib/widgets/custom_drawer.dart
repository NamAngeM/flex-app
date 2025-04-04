import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // Use FutureBuilder to handle the async getCurrentUser method
    return FutureBuilder<UserModel?>(
      future: authService.getCurrentUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user?.fullName ?? 'Utilisateur',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Accueil'),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),
              ListTile(
                leading: const Icon(Icons.restaurant),
                title: const Text('Restaurants'),
                onTap: () {
                  Navigator.pushNamed(context, '/restaurants');
                },
              ),
              ListTile(
                leading: const Icon(Icons.hotel),
                title: const Text('Hôtels'),
                onTap: () {
                  Navigator.pushNamed(context, '/hotels');
                },
              ),
              ListTile(
                leading: const Icon(Icons.book),
                title: const Text('Mes réservations'),
                onTap: () {
                  // Utiliser une route nommée avec des arguments
                  Navigator.pushNamed(context, '/hotels');
                  
                  // Afficher un message temporaire
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La fonctionnalité "Mes réservations" sera bientôt disponible'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Paramètres'),
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Déconnexion'),
                onTap: () async {
                  await authService.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}