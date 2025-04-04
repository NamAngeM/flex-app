// Fichier: lib/widgets/skeleton_loader.dart
import 'package:flutter/material.dart';

/// Un widget qui affiche un effet de chargement de type "skeleton" (squelette)
/// pour indiquer que le contenu est en cours de chargement
class SkeletonLoader extends StatefulWidget {
  final double height;
  final double width;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration animationDuration;
  final BoxShape shape;
  final EdgeInsetsGeometry margin;

  const SkeletonLoader({
    Key? key,
    this.height = 20,
    this.width = double.infinity,
    this.borderRadius = 8,
    this.baseColor,
    this.highlightColor,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.shape = BoxShape.rectangle,
    this.margin = EdgeInsets.zero,
  }) : super(key: key);

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBaseColor = widget.baseColor ?? 
        theme.colorScheme.onSurface.withOpacity(0.1);
    final defaultHighlightColor = widget.highlightColor ?? 
        theme.colorScheme.onSurface.withOpacity(0.05);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: widget.margin,
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.rectangle
                ? BorderRadius.circular(widget.borderRadius)
                : null,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                defaultBaseColor,
                defaultHighlightColor,
                defaultBaseColor,
              ],
              stops: [
                0.0,
                (_animation.value + 2) / 4, // Normalize to 0.0 - 1.0
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget pour afficher un texte en cours de chargement
class SkeletonText extends StatelessWidget {
  final double height;
  final double width;
  final EdgeInsetsGeometry margin;
  final int lines;
  final double lineSpacing;
  final double lastLineWidth;

  const SkeletonText({
    Key? key,
    this.height = 16,
    this.width = double.infinity,
    this.margin = EdgeInsets.zero,
    this.lines = 1,
    this.lineSpacing = 8,
    this.lastLineWidth = 0.6, // 60% de la largeur totale
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        final isLastLine = index == lines - 1;
        final lineWidth = isLastLine && lines > 1
            ? (width != double.infinity ? width * lastLineWidth : 150.0)
            : width;

        return Padding(
          padding: EdgeInsets.only(bottom: isLastLine ? 0 : lineSpacing),
          child: SkeletonLoader(
            height: height,
            width: lineWidth.toDouble(),
            margin: margin,
          ),
        );
      }),
    );
  }
}

/// Widget pour afficher une carte en cours de chargement
class SkeletonCard extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Widget? child;

  const SkeletonCard({
    Key? key,
    this.height = 120,
    this.width = double.infinity,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(vertical: 8),
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: height,
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child ?? _defaultCardContent(),
      ),
    );
  }

  Widget _defaultCardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SkeletonLoader(
              height: 40,
              width: 40,
              shape: BoxShape.circle,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonText(height: 14, width: 120),
                  SizedBox(height: 8),
                  SkeletonText(height: 12, width: 80),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Expanded(
          child: SkeletonText(
            lines: 2,
            lineSpacing: 8,
            height: 12,
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher une liste de cartes en cours de chargement
class SkeletonCardList extends StatelessWidget {
  final int itemCount;
  final double cardHeight;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  const SkeletonCardList({
    Key? key,
    this.itemCount = 3,
    this.cardHeight = 120,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.scrollable = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final listItems = List.generate(
      itemCount,
      (index) => SkeletonCard(
        height: cardHeight,
        margin: const EdgeInsets.only(bottom: 16),
      ),
    );

    if (scrollable) {
      return ListView(
        padding: padding,
        children: listItems,
      );
    } else {
      return Padding(
        padding: padding,
        child: Column(
          children: listItems,
        ),
      );
    }
  }
}