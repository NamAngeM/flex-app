// lib/screens/email_verification_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isEmailVerified = false;
  bool _canResendEmail = true;
  Timer? _timer;
  int _countDown = 60;

  @override
  void initState() {
    super.initState();
    _checkEmailVerified();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    final authService = context.read<AuthService>();
    
    // Vérifier immédiatement
    _isEmailVerified = authService.isEmailVerified();
    if (_isEmailVerified) {
      _timer?.cancel();
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    // Configurer un timer pour vérifier périodiquement
    _timer = Timer.periodic(Duration(seconds: 3), (_) async {
      final verified = await authService.reloadUser();
      if (verified) {
        _timer?.cancel();
        setState(() => _isEmailVerified = true);
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _canResendEmail = false);
    
    try {
      await context.read<AuthService>().sendVerificationEmail();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email de vérification envoyé')),
      );
      
      // Configurer un compte à rebours pour le renvoi
      _countDown = 60;
      Timer.periodic(Duration(seconds: 1), (timer) {
        if (_countDown > 0) {
          setState(() => _countDown--);
        } else {
          timer.cancel();
          setState(() => _canResendEmail = true);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi de l\'email: $e')),
      );
      setState(() => _canResendEmail = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vérification de l\'email'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mark_email_unread,
              size: 80,
              color: Colors.blue,
            ),
            SizedBox(height: 24),
            Text(
              'Vérifiez votre email',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Nous avons envoyé un email de vérification à votre adresse. Veuillez cliquer sur le lien dans l\'email pour vérifier votre compte.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _canResendEmail ? _resendVerificationEmail : null,
              child: Text(_canResendEmail 
                ? 'Renvoyer l\'email' 
                : 'Renvoyer dans $_countDown secondes'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _timer?.cancel();
                context.read<AuthService>().signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text('Retour à la connexion'),
            ),
          ],
        ),
      ),
    );
  }
}