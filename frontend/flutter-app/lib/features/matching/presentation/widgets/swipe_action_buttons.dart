import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Bottom action buttons for the swipe card interface.
class SwipeActionButtons extends StatelessWidget {
  final VoidCallback onDislike;
  final VoidCallback onSuperLike;
  final VoidCallback onLike;
  final VoidCallback onRewind;

  const SwipeActionButtons({
    super.key,
    required this.onDislike,
    required this.onSuperLike,
    required this.onLike,
    required this.onRewind,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Rewind
        _ActionButton(
          icon: Icons.refresh_rounded,
          color: AppTheme.accentGold,
          size: 44,
          onTap: onRewind,
          tooltip: 'Undo',
        ),

        // Dislike (X)
        _ActionButton(
          icon: Icons.close_rounded,
          color: AppTheme.error,
          size: 56,
          onTap: onDislike,
          tooltip: 'Pass',
        ),

        // Super Like (⭐)
        _ActionButton(
          icon: Icons.star_rounded,
          color: AppTheme.accentCyan,
          size: 44,
          onTap: onSuperLike,
          tooltip: 'Super Like',
        ),

        // Like (❤️)
        _ActionButton(
          icon: Icons.favorite_rounded,
          color: AppTheme.primaryPink,
          size: 56,
          onTap: onLike,
          tooltip: 'Like',
        ),

        // Game challenge (🎮)
        _ActionButton(
          icon: Icons.gamepad_rounded,
          color: AppTheme.primaryPurple,
          size: 44,
          onTap: () {}, // Challenge to game — shown after matching
          tooltip: 'Play',
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon, required this.color, required this.size,
    required this.onTap, required this.tooltip,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.85)
              .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.darkCard,
              border: Border.all(color: widget.color.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.2),
                  blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(widget.icon, color: widget.color,
                size: widget.size * 0.45),
          ),
        ),
      ),
    );
  }
}
