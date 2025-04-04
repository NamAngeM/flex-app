// lib/widgets/gradient_button.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isFullWidth;
  final double? height;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Gradient? gradient;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  const GradientButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = false,
    this.height = 48.0,
    this.elevation = 2.0,
    this.borderRadius,
    this.gradient,
    this.padding,
    this.textStyle,
  }) : super(key: key);

  @override
  _GradientButtonState createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> with SingleTickerProviderStateMixin {
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
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(AppTheme.radius_xl);
    
    // Default gradient from primary to secondary color
    final defaultGradient = widget.gradient ?? LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppTheme.primaryColor,
        AppTheme.secondaryColor,
      ],
    );
    
    final Widget buttonChild = widget.isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                  color: Colors.white,
                ),
                SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: widget.textStyle ?? TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          );

    final button = GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: widget.height,
          width: widget.isFullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            gradient: defaultGradient,
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: widget.elevation! * 2,
                spreadRadius: widget.elevation! * 0.2,
                offset: Offset(0, widget.elevation! * 0.5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: borderRadius,
              splashColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.white.withOpacity(0.05),
              child: Padding(
                padding: widget.padding ?? EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: widget.isFullWidth ? 24 : 16,
                ),
                child: Center(child: buttonChild),
              ),
            ),
          ),
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

// Floating action button with gradient background
class GradientFloatingActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Gradient? gradient;
  final Color? foregroundColor;

  const GradientFloatingActionButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.gradient,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final defaultGradient = gradient ?? LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppTheme.primaryColor,
        AppTheme.secondaryColor,
      ],
    );

    return Container(
      decoration: BoxDecoration(
        gradient: defaultGradient,
        borderRadius: BorderRadius.circular(AppTheme.radius_l),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: foregroundColor ?? Colors.white,
        elevation: 0,
        highlightElevation: 0,
        splashColor: Colors.white.withOpacity(0.1),
      ),
    );
  }
}