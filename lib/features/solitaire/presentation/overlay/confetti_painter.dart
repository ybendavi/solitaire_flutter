import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Particule de confetti
class ConfettiParticle {
  ConfettiParticle({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });

  double x;
  double y;
  double velocityX;
  double velocityY;
  final Color color;
  final double size;
  double rotation;
  final double rotationSpeed;
}

/// CustomPainter pour l'animation de confettis
class ConfettiPainter extends CustomPainter {
  ConfettiPainter({
    required this.progress,
    required this.colorScheme,
  }) {
    _generateParticles();
  }

  final double progress;
  final ColorScheme colorScheme;
  final List<ConfettiParticle> _particles = [];

  static const int _particleCount = 120;
  static const double _gravity = 200; // pixels per second²

  void _generateParticles() {
    if (_particles.isNotEmpty) return;

    final random = math.Random();
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      Colors.yellow.shade600,
      Colors.red.shade400,
      Colors.green.shade400,
      Colors.blue.shade400,
      Colors.purple.shade400,
    ];

    for (var i = 0; i < _particleCount; i++) {
      _particles.add(
        ConfettiParticle(
          x: random.nextDouble() * 400, // Largeur de départ
          y: -random.nextDouble() * 100, // Commencer au-dessus de l'écran
          velocityX: (random.nextDouble() - 0.5) * 200, // -100 à 100 px/s
          velocityY:
              random.nextDouble() * 100 + 50, // 50 à 150 px/s vers le bas
          color: colors[random.nextInt(colors.length)],
          size: random.nextDouble() * 8 + 4, // 4-12 px
          rotation: random.nextDouble() * math.pi * 2,
          rotationSpeed:
              (random.nextDouble() - 0.5) * 4, // rotation par seconde
        ),
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;

    // Temps en secondes basé sur le progress
    final timeSeconds = progress * 2.2; // durée de 2.2 secondes

    for (final particle in _particles) {
      // Mise à jour de la position basée sur la physique
      final newX = particle.x + particle.velocityX * timeSeconds;
      final newY = particle.y +
          particle.velocityY * timeSeconds +
          0.5 * _gravity * timeSeconds * timeSeconds;

      // Ne dessiner que si la particule est visible
      if (newX >= -20 &&
          newX <= size.width + 20 &&
          newY >= -20 &&
          newY <= size.height + 20) {
        paint.color = particle.color.withOpacity(
          (1.0 - (newY / size.height).clamp(0.0, 1.0)) * 0.9,
        );

        canvas.save();
        canvas.translate(newX, newY);
        canvas.rotate(particle.rotation + particle.rotationSpeed * timeSeconds);

        // Dessiner la particule comme un petit rectangle
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size * 0.6,
            ),
            const Radius.circular(2),
          ),
          paint,
        );

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
