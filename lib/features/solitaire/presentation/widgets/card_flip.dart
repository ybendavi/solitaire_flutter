import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Widget réutilisable pour animer le retournement d'une carte (faceDown → faceUp)
class CardFlip extends StatefulWidget {
  const CardFlip({
    required this.frontWidget,
    required this.backWidget,
    required this.isFlipped,
    super.key,
    this.duration = const Duration(milliseconds: 150),
    this.onFlipComplete,
  });

  /// Widget affiché face visible (face up)
  final Widget frontWidget;

  /// Widget affiché dos (face down)
  final Widget backWidget;

  /// État actuel: true = face visible, false = dos
  final bool isFlipped;

  /// Durée de l'animation
  final Duration duration;

  /// Callback appelé à la fin de l'animation
  final VoidCallback? onFlipComplete;

  @override
  State<CardFlip> createState() => _CardFlipState();
}

class _CardFlipState extends State<CardFlip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;
  late Animation<double> _scaleAnimation;

  bool _showFront = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Animation de rotation sur l'axe Y (0 → π)
    _flipAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Léger effet de scale pour plus de dynamisme
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeIn),
      ),
    );

    _showFront = widget.isFlipped;

    // Écouter les changements d'animation pour changer le widget au milieu
    _flipAnimation.addListener(() {
      if (_flipAnimation.value >= 0.5 && !_showFront && widget.isFlipped) {
        setState(() {
          _showFront = true;
        });
      } else if (_flipAnimation.value < 0.5 &&
          _showFront &&
          !widget.isFlipped) {
        setState(() {
          _showFront = false;
        });
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFlipComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(CardFlip oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isFlipped != widget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Calcul de l'angle de rotation (0 à π)
        final angle = _flipAnimation.value * math.pi;

        // Déterminer quel côté afficher
        final showingFront = angle > (math.pi / 2);

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..scale(_scaleAnimation.value + (1.0 - _scaleAnimation.value))
            ..rotateY(angle),
          child: showingFront
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: widget.frontWidget,
                )
              : widget.backWidget,
        );
      },
    );
  }
}

/// Widget simplifié pour faire un flip automatique une seule fois
class AutoCardFlip extends StatefulWidget {
  const AutoCardFlip({
    required this.frontWidget,
    required this.backWidget,
    super.key,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 150),
    this.onFlipComplete,
  });

  final Widget frontWidget;
  final Widget backWidget;
  final Duration delay;
  final Duration duration;
  final VoidCallback? onFlipComplete;

  @override
  State<AutoCardFlip> createState() => _AutoCardFlipState();
}

class _AutoCardFlipState extends State<AutoCardFlip> {
  bool _flipped = false;

  @override
  void initState() {
    super.initState();

    // Démarrer le flip après le délai
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _flipped = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CardFlip(
      frontWidget: widget.frontWidget,
      backWidget: widget.backWidget,
      isFlipped: _flipped,
      duration: widget.duration,
      onFlipComplete: widget.onFlipComplete,
    );
  }
}
