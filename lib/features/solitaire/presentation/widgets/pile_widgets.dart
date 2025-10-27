import 'package:flutter/material.dart';
import 'package:solitaire_klondike/core/theme/app_theme.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/card.dart'
    as game;

/// Widget placeholder pour les piles vides avec contraste amélioré
class PilePlaceholder extends StatelessWidget {
  const PilePlaceholder({
    required this.type,
    super.key,
    this.onTap,
    this.width = 63,
    this.height = 88,
  });

  final String type;
  final VoidCallback? onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: gameColors.cardBorder.withOpacity(0.3),
            width: 2,
          ),
          color: _getBackgroundColor(gameColors),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _buildContent(gameColors),
      ),
    );
  }

  Color _getBackgroundColor(GameColors gameColors) {
    switch (type) {
      case 'stock':
      case 'waste':
        return gameColors.tableBackground.withOpacity(0.2);
      case 'foundation':
        return gameColors.tableBackground.withOpacity(0.18);
      case 'tableau':
        return gameColors.tableBackground.withOpacity(0.15);
      default:
        return gameColors.tableBackground.withOpacity(0.2);
    }
  }

  Widget _buildContent(GameColors gameColors) {
    switch (type) {
      case 'stock':
        return Icon(
          Icons.refresh,
          color: gameColors.cardBorder.withOpacity(0.4),
          size: 24,
        );
      case 'waste':
        return Icon(
          Icons.visibility,
          color: gameColors.cardBorder.withOpacity(0.4),
          size: 20,
        );
      case 'foundation':
        return _buildFoundationIcon(gameColors);
      case 'tableau':
        return Icon(
          Icons.crop_portrait,
          color: gameColors.cardBorder.withOpacity(0.3),
          size: 32,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFoundationIcon(GameColors gameColors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.home,
          color: gameColors.cardBorder.withOpacity(0.4),
          size: 20,
        ),
        const SizedBox(height: 4),
        Container(
          width: 16,
          height: 2,
          decoration: BoxDecoration(
            color: gameColors.cardBorder.withOpacity(0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}

/// Widget pour les zones de drop avec feedback visuel
class PileDropTarget extends StatefulWidget {
  const PileDropTarget({
    required this.child,
    super.key,
    this.onAccept,
    this.onWillAccept,
    this.onMove,
    this.onLeave,
  });

  final Widget child;
  final void Function(game.Card)? onAccept;
  final bool Function(game.Card?)? onWillAccept;
  final void Function(DragTargetDetails<game.Card>)? onMove;
  final void Function(game.Card?)? onLeave;

  @override
  State<PileDropTarget> createState() => _PileDropTargetState();
}

class _PileDropTargetState extends State<PileDropTarget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<game.Card>(
      onAcceptWithDetails: (details) {
        _setHovering(false);
        widget.onAccept?.call(details.data);
      },
      onWillAcceptWithDetails: (details) {
        final willAccept = widget.onWillAccept?.call(details.data) ?? true;
        if (willAccept != _isHovering) {
          _setHovering(willAccept);
        }
        return willAccept;
      },
      onMove: (details) {
        widget.onMove?.call(details);
      },
      onLeave: (data) {
        _setHovering(false);
        widget.onLeave?.call(data);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: _isHovering
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      )
                    : null,
                child: widget.child,
              ),
            );
          },
        );
      },
    );
  }

  void _setHovering(bool hovering) {
    if (_isHovering != hovering) {
      setState(() {
        _isHovering = hovering;
      });
      if (hovering) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }
}

/// Widget de debug pour visualiser les zones de drop
class DebugOverlay extends StatelessWidget {
  const DebugOverlay({
    required this.debugRects,
    super.key,
  });

  final List<dynamic> debugRects;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _DebugPainter(debugRects),
        size: Size.infinite,
      ),
    );
  }
}

class _DebugPainter extends CustomPainter {
  _DebugPainter(this.debugRects);
  final List<dynamic> debugRects;

  @override
  void paint(Canvas canvas, Size size) {
    for (final debugRect in debugRects) {
      // Dessiner le rectangle semi-transparent
      final paint = Paint()
        ..color = (debugRect.color as Color).withOpacity(0.2)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            debugRect.rect as Rect, const Radius.circular(8)),
        paint,
      );

      // Dessiner le contour
      final borderPaint = Paint()
        ..color = debugRect.color as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            debugRect.rect as Rect, const Radius.circular(8)),
        borderPaint,
      );

      // Dessiner le label
      final textPainter = TextPainter(
        text: TextSpan(
          text: debugRect.label as String,
          style: TextStyle(
            color: debugRect.color as Color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.7),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final rect = debugRect.rect as Rect;
      final textOffset = Offset(
        rect.left + 4,
        rect.top + 4,
      );
      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
