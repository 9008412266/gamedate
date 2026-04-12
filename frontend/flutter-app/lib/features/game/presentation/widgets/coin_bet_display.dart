import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CoinBetDisplay extends StatelessWidget {
  final int coinsBet;
  const CoinBetDisplay({super.key, required this.coinsBet});

  @override
  Widget build(BuildContext context) {
    if (coinsBet == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentGold),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on, color: AppTheme.accentGold, size: 16),
          const SizedBox(width: 4),
          Text('$coinsBet coins', style: TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}