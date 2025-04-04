// Fichier: lib/widgets/modern_card.dart
import 'package:flutter/material.dart';
import 'dart:ui';

/// Un widget de carte moderne avec des effets d'ombre avancés et des animations
class ModernCard extends StatefulWidget {
  final Widget child;
  final double elevation;
  final double borderRadius;
  final Color? shadowColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Duration animationDuration;
  final bool enableHoverEffect;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Border? border;

  const ModernCard({
    Key? key,
    required this.child,
    this.elevation = 4.0,
    this.borderRadius = 16.0,
    this.shadowColor,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.all(8.0),
    this.animationDuration = const Duration(milliseconds: 200),
    this.enableHoverEffect = true,
    this.onTap,
    this.gradient,
    this.border,
  }) : super(key: key);

  @override
  State<ModernCard> createState() => _ModernCardState();
}

class _ModernCardState extends State<ModernCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.elevation + 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovered) {
    if (!widget.enableHoverEffect) return;
    
    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultShadowColor = widget.shadowColor ?? theme.shadowColor.withOpacity(0.3);
    final defaultBackgroundColor = widget.backgroundColor ?? theme.cardColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return MouseRegion(
          onEnter: (_) => _onHoverChanged(true),
          onExit: (_) => _onHoverChanged(false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Transform.scale(
              scale: widget.enableHoverEffect ? _scaleAnimation.value : 1.0,
              child: Container(
                margin: widget.margin,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  boxShadow: [
                    // Ombre principale
                    BoxShadow(
                      color: defaultShadowColor,
                      blurRadius: _elevationAnimation.value * 2,
                      spreadRadius: _elevationAnimation.value * 0.5,
                      offset: Offset(0, _elevationAnimation.value),
                    ),
                    // Ombre légère en haut pour un effet 3D
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 3.0,
                      spreadRadius: 0.0,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: Container(
                      padding: widget.padding,
                      decoration: BoxDecoration(
                        color: widget.gradient == null ? defaultBackgroundColor : null,
                        gradient: widget.gradient,
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        border: widget.border ?? Border.all(
                          color: _isHovered 
                              ? theme.colorScheme.primary.withOpacity(0.3)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Une version de ModernCard avec un dégradé par défaut
class GradientModernCard extends StatelessWidget {
  final Widget child;
  final double elevation;
  final double borderRadius;
  final Color? shadowColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Duration animationDuration;
  final bool enableHoverEffect;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Border? border;

  const GradientModernCard({
    Key? key,
    required this.child,
    this.elevation = 4.0,
    this.borderRadius = 16.0,
    this.shadowColor,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.all(8.0),
    this.animationDuration = const Duration(milliseconds: 200),
    this.enableHoverEffect = true,
    this.onTap,
    this.gradient,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultGradient = gradient ?? LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        theme.colorScheme.primary.withOpacity(0.8),
        theme.colorScheme.secondary.withOpacity(0.9),
      ],
    );

    return ModernCard(
      child: child,
      elevation: elevation,
      borderRadius: borderRadius,
      shadowColor: shadowColor,
      padding: padding,
      margin: margin,
      animationDuration: animationDuration,
      enableHoverEffect: enableHoverEffect,
      onTap: onTap,
      gradient: defaultGradient,
      border: border,
    );
  }
}