import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../widgets/button_widget.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _fullName = '';
  String _phoneNumber = '';
  UserRole _selectedRole = UserRole.client;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppTheme.animationDurationMedium,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double _calculatePasswordStrength(String password) {
    double strength = 0.0;
    if (password.length >= 8) strength += 0.2;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.2;
    if (password.length >= 12) strength += 0.2;
    return strength;
  }

  Color _getPasswordStrengthColor(double strength) {
    if (strength < 0.5) return AppTheme.errorColor;
    if (strength < 0.8) return AppTheme.warningColor;
    return AppTheme.successColor;
  }

  String _getPasswordStrengthText(double strength) {
    if (strength < 0.5) return 'Mot de passe faible';
    if (strength < 0.8) return 'Mot de passe moyen';
    return 'Mot de passe fort';
  }

  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      print('Validation du formulaire réussie');
      print('Email: $_email');
      print('Nom complet: $_fullName');
      print('Téléphone: $_phoneNumber');
      print('Rôle: $_selectedRole');

      if (_password != _confirmPassword) {
        print('Erreur: Les mots de passe ne correspondent pas');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Les mots de passe ne correspondent pas'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);
      print('Début du processus d\'inscription...');

      try {
        print('Appel de _authService.signUpWithEmail');
        final user = await _authService.signUpWithEmail(
          email: _email,
          password: _password,
          fullName: _fullName,
          phoneNumber: _phoneNumber,
          role: _selectedRole,
        );

        print('Résultat de l\'inscription: ${user != null ? "Succès" : "Échec"}');

        if (user != null) {
          print('Navigation vers l\'écran de vérification d\'email');
          Navigator.pushReplacementNamed(context, '/email-verification');
        } else {
          print('Utilisateur null après inscription');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Échec de l\'inscription: aucun utilisateur retourné'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } catch (e) {
        print('Exception lors de l\'inscription: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'inscription: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } finally {
        print('Fin du processus d\'inscription');
        setState(() => _isLoading = false);
      }
    } else {
      print('Validation du formulaire échouée');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // En-tête
                  SizedBox(height: 20),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Créer un compte',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: 48), // Pour équilibrer l'en-tête
                    ],
                  ),
                  SizedBox(height: 24),

                  // Texte d'introduction
                  Text(
                    'Rejoignez-nous pour accéder à tous nos services',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),

                  // Champ nom complet
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Nom complet',
                      hintText: 'Aminata Ndiaye',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radius_m),
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) =>
                        value!.isEmpty ? 'Veuillez entrer votre nom' : null,
                    onSaved: (value) => _fullName = value!,
                  ),
                  SizedBox(height: 20),

                  // Champ email
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'exemple@email.com',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radius_m),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Veuillez entrer votre email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Veuillez entrer un email valide';
                      }
                      return null;
                    },
                    onSaved: (value) => _email = value!,
                  ),
                  SizedBox(height: 20),

                  // Champ téléphone
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Téléphone',
                      hintText: '06 12 34 56 78',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radius_m),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        value!.isEmpty ? 'Veuillez entrer votre numéro' : null,
                    onSaved: (value) => _phoneNumber = value!,
                  ),
                  SizedBox(height: 20),

                  // Champ mot de passe avec indicateur de force
                  StatefulBuilder(
                    builder: (context, setState) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              hintText: '••••••••',
                              prefixIcon: Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radius_m),
                              ),
                            ),
                            obscureText: _obscurePassword,
                            onChanged: (value) {
                              setState(() {
                                _password = value;
                              });
                            },
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Veuillez entrer un mot de passe';
                              }
                              if (value.length < 8) {
                                return 'Le mot de passe doit contenir au moins 8 caractères';
                              }
                              if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                return 'Le mot de passe doit contenir au moins une majuscule';
                              }
                              if (!RegExp(r'[0-9]').hasMatch(value)) {
                                return 'Le mot de passe doit contenir au moins un chiffre';
                              }
                              if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                                return 'Le mot de passe doit contenir au moins un caractère spécial';
                              }
                              return null;
                            },
                            onSaved: (value) => _password = value!,
                          ),
                          if (_password.isNotEmpty) ...[
                            SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppTheme.radius_xs),
                                color: theme.colorScheme.surface,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: LinearProgressIndicator(
                                value: _calculatePasswordStrength(_password),
                                backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                                color: _getPasswordStrengthColor(_calculatePasswordStrength(_password)),
                                minHeight: 4,
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  _calculatePasswordStrength(_password) < 0.5
                                      ? Icons.info_outline
                                      : (_calculatePasswordStrength(_password) < 0.8
                                          ? Icons.check_circle_outline
                                          : Icons.verified_outlined),
                                  size: 14,
                                  color: _getPasswordStrengthColor(_calculatePasswordStrength(_password)),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  _getPasswordStrengthText(_calculatePasswordStrength(_password)),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getPasswordStrengthColor(_calculatePasswordStrength(_password)),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 20),

                  // Champ confirmation mot de passe
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      hintText: '••••••••',
                      prefixIcon: Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        onPressed: () {
                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radius_m),
                      ),
                    ),
                    obscureText: _obscureConfirmPassword,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Veuillez confirmer le mot de passe';
                      }
                      if (value != _password) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                    onSaved: (value) => _confirmPassword = value!,
                  ),
                  SizedBox(height: 20),

                  // Sélection du type de compte
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radius_m),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 12),
                          child: Text(
                            'Type de compte',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        RadioListTile<UserRole>(
                          title: Text('Client'),
                          subtitle: Text('Réservez des services'),
                          value: UserRole.client,
                          groupValue: _selectedRole,
                          onChanged: (value) {
                            setState(() => _selectedRole = value!);
                          },
                          activeColor: theme.colorScheme.primary,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        ),
                        RadioListTile<UserRole>(
                          title: Text('Prestataire'),
                          subtitle: Text('Proposez vos services'),
                          value: UserRole.provider,
                          groupValue: _selectedRole,
                          onChanged: (value) {
                            setState(() => _selectedRole = value!);
                          },
                          activeColor: theme.colorScheme.primary,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),

                  // Bouton d'inscription
                  AppButton(
                    text: 'Créer mon compte',
                    onPressed: _handleSignUp,
                    isLoading: _isLoading,
                    isPrimary: true,
                    isFullWidth: true,
                    height: 54,
                  ),
                  SizedBox(height: 20),

                  // Séparateur
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: theme.colorScheme.onBackground.withOpacity(0.2),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OU',
                          style: TextStyle(
                            color: theme.colorScheme.onBackground.withOpacity(0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: theme.colorScheme.onBackground.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Bouton Google
                  AppButton(
                    text: 'Continuer avec Google',
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      try {
                        final user = await _authService.signInWithGoogle();
                        if (user != null) {
                          Navigator.pushReplacementNamed(context, '/home');
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur de connexion Google: $e'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: theme.colorScheme.error,
                          ),
                        );
                      } finally {
                        setState(() => _isLoading = false);
                      }
                    },
                    isLoading: _isLoading,
                    isPrimary: false,
                    isFullWidth: true,
                    height: 54,
                    icon: Icons.login,
                  ),
                  SizedBox(height: 24),

                  // Lien de connexion
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Déjà un compte ?',
                        style: TextStyle(
                          color: theme.colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                        child: Text(
                          'Se connecter',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}