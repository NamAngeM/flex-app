// Fichier: lib/screens/confirm_reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../utils/validators.dart';
import '../utils/constants.dart';
import '../utils/snackbar_utils.dart';

class ConfirmResetPasswordScreen extends StatefulWidget {
  static const String routeName = '/confirm-reset-password';
  final String oobCode;

  const ConfirmResetPasswordScreen({
    Key? key,
    required this.oobCode,
  }) : super(key: key);

  @override
  _ConfirmResetPasswordScreenState createState() => _ConfirmResetPasswordScreenState();
}

class _ConfirmResetPasswordScreenState extends State<ConfirmResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Map<String, bool> _passwordStrength = {
    'length': false,
    'uppercase': false,
    'lowercase': false,
    'number': false,
    'special': false,
  };

  @override
  void initState() {
    super.initState();
    _verifyCode();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Vérifier si le code est valide
  Future<void> _verifyCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.checkActionCode(widget.oobCode);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        showErrorSnackBar(
          context, 
          'Ce lien est invalide ou a expiré. Veuillez demander un nouveau lien de réinitialisation.'
        );
        
        // Rediriger vers l'écran de réinitialisation après un délai
        Future.delayed(Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/reset-password');
          }
        });
      }
    }
  }

  // Mettre à jour l'indicateur de force du mot de passe
  void _updatePasswordStrength(String password) {
    setState(() {
      _passwordStrength = {
        'length': password.length >= 8,
        'uppercase': RegExp(r'[A-Z]').hasMatch(password),
        'lowercase': RegExp(r'[a-z]').hasMatch(password),
        'number': RegExp(r'[0-9]').hasMatch(password),
        'special': RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password),
      };
    });
  }

  // Confirmer la réinitialisation du mot de passe
  Future<void> _confirmResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.confirmPasswordReset(
        widget.oobCode,
        _passwordController.text,
      );
      
      setState(() {
        _isSuccess = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        showErrorSnackBar(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau mot de passe'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _isSuccess 
              ? _buildSuccessMessage() 
              : _buildResetPasswordForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildResetPasswordForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Image.asset(
            'assets/images/logo.png',
            height: 100,
          ),
          const SizedBox(height: 30),
          const Text(
            'Créer un nouveau mot de passe',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            'Votre nouveau mot de passe doit être différent des mots de passe précédemment utilisés.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          
          // Champ de mot de passe
          CustomTextField(
            controller: _passwordController,
            labelText: 'Nouveau mot de passe',
            hintText: 'Entrez votre nouveau mot de passe',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            onChanged: (value) {
              _updatePasswordStrength(value);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un mot de passe';
              }
              if (!_passwordStrength.values.every((isValid) => isValid)) {
                return 'Le mot de passe ne répond pas aux exigences';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Indicateur de force du mot de passe
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Votre mot de passe doit contenir:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildPasswordRequirement(
                'Au moins 8 caractères', 
                _passwordStrength['length']!
              ),
              _buildPasswordRequirement(
                'Au moins une lettre majuscule', 
                _passwordStrength['uppercase']!
              ),
              _buildPasswordRequirement(
                'Au moins une lettre minuscule', 
                _passwordStrength['lowercase']!
              ),
              _buildPasswordRequirement(
                'Au moins un chiffre', 
                _passwordStrength['number']!
              ),
              _buildPasswordRequirement(
                'Au moins un caractère spécial', 
                _passwordStrength['special']!
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Champ de confirmation de mot de passe
          CustomTextField(
            controller: _confirmPasswordController,
            labelText: 'Confirmer le mot de passe',
            hintText: 'Confirmez votre nouveau mot de passe',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez confirmer votre mot de passe';
              }
              if (value != _passwordController.text) {
                return 'Les mots de passe ne correspondent pas';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          
          // Bouton de confirmation
          CustomButton(
            text: 'Réinitialiser le mot de passe',
            isLoading: _isLoading,
            onPressed: _confirmResetPassword,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirement(String requirement, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            color: isMet ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            requirement,
            style: TextStyle(
              fontSize: 14,
              color: isMet ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: Colors.green,
          size: 80,
        ),
        const SizedBox(height: 30),
        const Text(
          'Mot de passe réinitialisé !',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        const Text(
          'Votre mot de passe a été réinitialisé avec succès. Vous pouvez maintenant vous connecter avec votre nouveau mot de passe.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        CustomButton(
          text: 'Se connecter',
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ],
    );
  }
}