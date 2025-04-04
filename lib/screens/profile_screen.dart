// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final profileService = Provider.of<ProfileService>(context, listen: false);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final theme = Theme.of(context);
    
    return Scaffold(
      body: StreamBuilder<UserModel?>(
        stream: profileService.profileStream(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            );
          }
          
          final user = snapshot.data;
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                  SizedBox(height: 16),
                  Text(
                    'Profil non trouvé',
                    style: theme.textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Retour'),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // En-tête avec photo de profil et nom
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Hero(
                            tag: 'profile-${user.uid}',
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                backgroundImage: user.photoUrl != null
                                    ? NetworkImage(user.photoUrl!)
                                    : null,
                                child: user.photoUrl == null
                                    ? Icon(Icons.person, size: 50, color: AppTheme.primaryColor)
                                    : null,
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            user.fullName,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  titlePadding: EdgeInsets.zero,
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.white),
                    onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
                    tooltip: 'Modifier le profil',
                  ),
                ],
              ),
              
              // Informations de l'utilisateur
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informations personnelles
                      _buildSectionHeader(context, 'Informations personnelles'),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        context,
                        children: [
                          _buildInfoRow(
                            context,
                            icon: Icons.email,
                            title: 'Email',
                            value: user.email,
                          ),
                          Divider(),
                          _buildInfoRow(
                            context,
                            icon: Icons.phone,
                            title: 'Téléphone',
                            value: user.phoneNumber,
                          ),
                          if (user.role == UserRole.provider) ...[
                            Divider(),
                            _buildInfoRow(
                              context,
                              icon: Icons.business,
                              title: 'Type de compte',
                              value: 'Prestataire',
                            ),
                          ],
                        ],
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Actions rapides
                      _buildSectionHeader(context, 'Actions rapides'),
                      SizedBox(height: 8),
                      _buildActionCard(
                        context,
                        children: [
                          _buildActionButton(
                            context,
                            icon: Icons.history,
                            label: 'Mes Rendez-vous',
                            onTap: () => Navigator.pushNamed(context, '/bookings'),
                          ),
                          _buildActionButton(
                            context,
                            icon: Icons.favorite,
                            label: 'Favoris',
                            onTap: () => Navigator.pushNamed(context, '/favorites'),
                          ),
                          _buildActionButton(
                            context,
                            icon: Icons.notifications,
                            label: 'Notifications',
                            onTap: () => Navigator.pushNamed(context, '/notifications'),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Paramètres
                      _buildSectionHeader(context, 'Paramètres'),
                      SizedBox(height: 8),
                      _buildMenuCard(
                        context,
                        children: [
                          _buildMenuItem(
                            context,
                            icon: Icons.settings,
                            title: 'Paramètres',
                            onTap: () => Navigator.pushNamed(context, '/settings'),
                          ),
                          _buildMenuItem(
                            context,
                            icon: Icons.help,
                            title: 'Aide et support',
                            onTap: () => Navigator.pushNamed(context, '/help'),
                          ),
                          _buildMenuItem(
                            context,
                            icon: Icons.exit_to_app,
                            title: 'Déconnexion',
                            iconColor: AppTheme.errorColor,
                            textColor: AppTheme.errorColor,
                            onTap: () async {
                              // Confirmation de déconnexion
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Déconnexion'),
                                  content: Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text('Annuler'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: Text('Déconnexion'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.errorColor,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (confirm == true) {
                                await Provider.of<AuthService>(context, listen: false).signOut();
                                Navigator.pushReplacementNamed(context, '/login');
                              }
                            },
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
  
  Widget _buildInfoCard(BuildContext context, {required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius_l),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionCard(BuildContext context, {required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius_l),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: children,
        ),
      ),
    );
  }
  
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radius_m),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMenuCard(BuildContext context, {required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius_l),
      ),
      child: Column(
        children: children,
      ),
    );
  }
  
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? Colors.grey[700],
              size: 20,
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor ?? Colors.grey[800],
              ),
            ),
            Spacer(),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}