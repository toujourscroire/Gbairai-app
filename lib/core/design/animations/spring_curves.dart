import 'package:flutter/material.dart';

abstract final class GCurves {
  // iOS-like spring pour les compteurs et réactions
  static const spring = SpringCurve();
  static const springBounce = SpringCurve(damping: 0.6, stiffness: 600);
  static const easeOutQuart = Cubic(0.25, 1.0, 0.5, 1.0);
  static const easeInOutQuart = Cubic(0.76, 0, 0.24, 1);
  static const easeOutBack = Cubic(0.34, 1.56, 0.64, 1);
}

// Courbe spring personnalisée (simulation physique simplifiée)
class SpringCurve extends Curve {
  final double damping;
  final double stiffness;

  const SpringCurve({this.damping = 0.8, this.stiffness = 400});

  @override
  double transformInternal(double t) {
    if (t == 0 || t == 1) return t;
    final omega = stiffness / 100;
    final envelope = damping < 1
        ? (1 - t) * (1 + omega * t)
        : 1 - (1 - t) * (1 + omega * t);
    return 1 - envelope * (1 - t);
  }
}

abstract final class GTransitions {
  // Transition slide-up premium pour les modals
  static Widget slideUp(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: GCurves.easeOutQuart)),
      child: child,
    );
  }

  // Transition fade + scale pour les alertes
  static Widget fadeScale(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: GCurves.easeOutBack),
        ),
        child: child,
      ),
    );
  }
}
