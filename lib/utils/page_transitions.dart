// lib/utils/page_transitions.dart
import 'package:flutter/material.dart';

class AppPageTransitions {
  // Transition par défaut à utiliser dans toute l'application
  static PageRouteBuilder defaultTransition({
    required Widget page,
    required RouteSettings settings,
  }) {
    return fadeTransition(page: page, settings: settings);
  }
  
  // Transition avec fondu
  static PageRouteBuilder fadeTransition({
    required Widget page,
    required RouteSettings settings,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
  
  // Transition avec glissement
  static PageRouteBuilder slideTransition({
    required Widget page,
    required RouteSettings settings,
    SlideDirection direction = SlideDirection.right,
  }) {
    Offset beginOffset;
    switch (direction) {
      case SlideDirection.right:
        beginOffset = const Offset(1.0, 0.0);
        break;
      case SlideDirection.left:
        beginOffset = const Offset(-1.0, 0.0);
        break;
      case SlideDirection.up:
        beginOffset = const Offset(0.0, 1.0);
        break;
      case SlideDirection.down:
        beginOffset = const Offset(0.0, -1.0);
        break;
    }
    
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
  
  // Transition avec échelle
  static PageRouteBuilder scaleTransition({
    required Widget page,
    required RouteSettings settings,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.9,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

enum SlideDirection {
  right,
  left,
  up,
  down,
}