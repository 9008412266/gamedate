import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class ChessBoardWidget extends StatelessWidget {
  final Map<String, dynamic>? gameState;
  final Function(Map<String, dynamic>)? onMove;

  const ChessBoardWidget({super.key, this.gameState, this.onMove});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
        itemCount: 64,
        itemBuilder: (_, i) {
          final row = i ~/ 8;
          final col = i % 8;
          final isLight = (row + col) % 2 == 0;
          return Container(
            color: isLight ? const Color(0xFFF0D9B5) : const Color(0xFFB58863),
          );
        },
      ),
    );
  }
}