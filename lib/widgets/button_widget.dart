// lib/widgets/button_widget.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isPrimary;
  final IconData? icon;
  final Color? color;
  final bool isFullWidth;
  final double? height;
  final double? elevation;
  final BorderRadius? borderRadius;

  const AppButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.icon,
    this.color,
    this.isFullWidth = false,
    this.height = 48.0,
    this.elevation,
    this.borderRadius,
  }) : super(key: key);

  @override
  _AppButtonState createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.animationDurationShort,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isLoading) {
      setState(() {
        _isPressed = true;
      });
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.isLoading) {
      setState(() {
        _isPressed = false;
      });
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (!widget.isLoading) {
      setState(() {
        _isPressed = false;
      });
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = widget.color ?? (widget.isPrimary ? theme.colorScheme.primary : null);
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(AppTheme.radius_m);
    
    final Widget buttonChild = widget.isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.isPrimary ? Colors.white : theme.colorScheme.primary,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 18,
                ),
                SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          );

    final buttonStyle = widget.isPrimary
        ? ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            elevation: _isPressed ? (widget.elevation ?? 2) / 2 : widget.elevation,
            shadowColor: buttonColor?.withOpacity(0.3),
            padding: EdgeInsets.symmetric(
              vertical: 0,
              horizontal: widget.isFullWidth ? 24 : 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius,
            ),
            minimumSize: Size(
              widget.isFullWidth ? double.infinity : 0,
              widget.height ?? 48,
            ),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: buttonColor,
            side: BorderSide(color: buttonColor ?? theme.colorScheme.primary, width: 1.5),
            padding: EdgeInsets.symmetric(
              vertical: 0,
              horizontal: widget.isFullWidth ? 24 : 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius,
            ),
            minimumSize: Size(
              widget.isFullWidth ? double.infinity : 0,
              widget.height ?? 48,
            ),
          );

    final button = GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.isPrimary
            ? ElevatedButton(
                onPressed: widget.isLoading ? null : widget.onPressed,
                style: buttonStyle,
                child: buttonChild,
              )
            : OutlinedButton(
                onPressed: widget.isLoading ? null : widget.onPressed,
                style: buttonStyle,
                child: buttonChild,
              ),
      ),
    );

    return widget.isFullWidth
        ? button
        : FittedBox(
            child: button,
          );
  }
}

// Bouton flottant d'action avec icône et texte
class AppFloatingActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppFloatingActionButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      backgroundColor: backgroundColor ?? theme.colorScheme.primary,
      foregroundColor: foregroundColor ?? Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius_l),
      ),
    );
  }
}

// Bouton d'icône avec effet d'ondulation
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final double size;
  final String? tooltip;
  final bool hasBadge;

  const AppIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = 24.0,
    this.tooltip,
    this.hasBadge = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: color ?? theme.colorScheme.primary,
          tooltip: tooltip,
          splashRadius: 24,
          iconSize: size,
        ),
        if (hasBadge)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}