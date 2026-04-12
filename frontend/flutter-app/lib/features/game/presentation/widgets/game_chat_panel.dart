import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class GameChatPanel extends StatelessWidget {
  const GameChatPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: AppTheme.darkSurface,
      padding: const EdgeInsets.all(8),
      child: const Center(
        child: Text('In-game chat', style: TextStyle(color: Colors.white38)),
      ),
    );
  }
}
