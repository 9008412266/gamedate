import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class LudoBoardWidget extends StatelessWidget {
  final Map<String, dynamic>? gameState;
  final Function(Map<String, dynamic>)? onMove;

  const LudoBoardWidget({super.key, this.gameState, this.onMove});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryPink.withValues(alpha: 0.3)),
        ),
        child: const Center(
          child: Text('Ludo Board', style: TextStyle(color: Colors.white54, fontSize: 18)),
        ),
      ),
    );
  }
}