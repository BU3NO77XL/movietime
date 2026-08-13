import 'package:flutter/material.dart';

Route<T> cinematicPageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final secondaryCurvedAnimation = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final slide = Tween<Offset>(
        begin: const Offset(0.06, 0.02),
        end: Offset.zero,
      ).animate(curvedAnimation);
      final scale = Tween<double>(
        begin: 0.985,
        end: 1,
      ).animate(curvedAnimation);
      final outgoingSlide = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.025, 0),
      ).animate(secondaryCurvedAnimation);

      return SlideTransition(
        position: outgoingSlide,
        child: FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: slide,
            child: ScaleTransition(scale: scale, child: child),
          ),
        ),
      );
    },
  );
}
