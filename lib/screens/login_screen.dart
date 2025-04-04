import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/button_widget.dart';

class TypingText extends StatefulWidget {
  final String text;
  final Duration speed;
  final bool loop;

  TypingText({required this.text, this.speed = const Duration(milliseconds: 100), this.loop = false});

  @override
  _TypingTextState createState() => _TypingTextState();
}

class _TypingTextState extends State<TypingText> {
  String _displayedText = "";
  int _index = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.speed, (timer) {
      if (_index < widget.text.length) {
        setState(() {
          _displayedText = widget.text.substring(0, _index + 1);
          _index++;
        });
      } else {
        if (widget.loop) {
          Future.delayed(Duration(seconds: 1), () {
            setState(() {
              _index = 0;
              _displayedText = "";
            });
          });
        } else {
          _timer.cancel();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onBackground,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  String _email = '';
  String _password = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _logoController;
  late Animation<double> _logoRotation;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _logoRotation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final user = await _authService.signInWithEmail(_email, _password);
        if (user != null) {
          final isVerified = _authService.isEmailVerified();
          if (isVerified) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            Navigator.pushReplacementNamed(context, '/email-verification');
          }
        } else {
          _showError("Identifiants incorrects ou compte inexistant");
        }
      } catch (e) {
        _showError("Erreur de connexion: $e");
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 40),

                  // Logo animé
                  Center(
                    child: AnimatedBuilder(
                      animation: _logoRotation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _logoRotation.value,
                          child: child,
                        );
                      },
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 100,
                      ),
                    ),
                  ),

                  SizedBox(height: 20),
                  TypingText(text: 'Bienvenue !', speed: Duration(milliseconds: 100)),
                  SizedBox(height: 8),
                  TypingText(
                      text: 'Flexibook, votre app pour vos rdv veuillez vous connecter pour continuer',
                      speed: Duration(milliseconds: 100),
                      loop: true),

                  SizedBox(height: 40),


                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'exemple@email.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) =>
                          value!.isEmpty ? 'Veuillez entrer votre email' : null,
                          onSaved: (value) => _email = value!,
                        ),
                        SizedBox(height: 20),

                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            hintText: '••••••••',
                            prefixIcon: Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) =>
                          value!.isEmpty ? 'Veuillez entrer votre mot de passe' : null,
                          onSaved: (value) => _password = value!,
                        ),
                      ],
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/reset-password'),
                      child: Text('Mot de passe oublié ?'),
                    ),
                  ),
                  SizedBox(height: 24),

                  AppButton(
                    text: 'Se connecter',
                    onPressed: _handleLogin,
                    isLoading: _isLoading,
                    isPrimary: true,
                    isFullWidth: true,
                    height: 54,
                  ),
                  SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Pas encore de compte ?',
                        style: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.7)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/signup'),
                        child: Text('S\'inscrire', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
