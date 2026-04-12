import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class GamePlayerCard extends StatelessWidget {
  final String playerName;
  final int rating;
  final bool isCurrentTurn;
  final int? timeRemaining;

  const GamePlayerCard({
    super.key,
    required this.playerName,
    required this.rating,
    this.isCurrentTurn = false,
    this.timeRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentTurn ? AppTheme.primaryPink.withOpacity(0.2) : AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentTurn ? Border.all(color: AppTheme.primaryPink) : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryPurple,
            child: Text(playerName.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(playerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Rating: $rating', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          if (timeRemaining != null)
            Text('${timeRemaining}s', style: TextStyle(
              color: timeRemaining! < 10 ? Colors.red : AppTheme.accentCyan,
              fontWeight: FontWeight.bold,
            )),
        ],
      ),
    );
  }
}