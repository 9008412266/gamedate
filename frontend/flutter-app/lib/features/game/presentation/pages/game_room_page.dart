import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/game_bloc.dart';
import '../widgets/chess/chess_board_widget.dart';
import '../widgets/ludo/ludo_board_widget.dart';
import '../widgets/game_player_card.dart';
import '../widgets/game_chat_panel.dart';
import '../widgets/coin_bet_display.dart';

class GameRoomPage extends StatefulWidget {
  final String roomId;
  final String gameType;

  const GameRoomPage({super.key, required this.roomId, required this.gameType});

  @override
  State<GameRoomPage> createState() => _GameRoomPageState();
}

class _GameRoomPageState extends State<GameRoomPage> {
  bool _isChatOpen = false;

  @override
  void initState() {
    super.initState();
    context.read<GameBloc>().add(JoinGameRoom(widget.roomId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_gameTypeEmoji(), style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(widget.gameType, style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: () => setState(() => _isChatOpen = !_isChatOpen),
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: Colors.white),
            onPressed: _showResignConfirmation,
          ),
        ],
      ),
      body: BlocConsumer<GameBloc, GameState>(
        listener: (context, state) {
          if (state is GameCompleted) _showGameOverDialog(state);
        },
        builder: (context, state) {
          if (state is GameLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is GameRoomActive) {
            return _buildGameLayout(state);
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Waiting for players...', style: TextStyle(color: Colors.white54)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameLayout(GameRoomActive state) {
    final players = (state.gameState['players'] as List<dynamic>?) ?? [];
    final coinsBet = (state.gameState['coinsBet'] as int?) ?? 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: players.map<Widget>((player) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GamePlayerCard(
                  playerName: player['name'] ?? 'Player',
                  rating: player['rating'] ?? 1200,
                  isCurrentTurn: player['isCurrentTurn'] ?? false,
                ),
              ),
            )).toList(),
          ),
        ),
        if (coinsBet > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CoinBetDisplay(coinsBet: coinsBet),
          ),
        Expanded(child: _buildBoard(state)),
        if (_isChatOpen) const GameChatPanel(),
      ],
    );
  }

  Widget _buildBoard(GameRoomActive state) {
    return switch (widget.gameType) {
      'CHESS' => ChessBoardWidget(gameState: state.gameState),
      'LUDO'  => LudoBoardWidget(gameState: state.gameState),
      _       => const Center(child: Text('Board loading...')),
    };
  }

  String _gameTypeEmoji() => switch (widget.gameType) {
    'CHESS'     => '♟️',
    'LUDO'      => '🎲',
    'BILLIARDS' => '🎱',
    _           => '🎮',
  };

  Future<void> _showResignConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Resign?'),
        content: const Text('Are you sure you want to resign?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Resign')),
        ],
      ),
    );
    if (confirm == true && mounted) {
      context.read<GameBloc>().add(SendGameAction('RESIGN', {}));
    }
  }

  void _showGameOverDialog(GameCompleted state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Game Over!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.winnerId == 'CURRENT_USER_ID' ? '🏆 You Win!' : '😔 You Lost',
              style: const TextStyle(fontSize: 32),
              textAlign: TextAlign.center,
            ),
            if (state.coinsEarned > 0) ...[
              const SizedBox(height: 16),
              Text('+${state.coinsEarned} coins!',
                style: const TextStyle(color: AppTheme.accentGold, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('Back to Lobby'),
          ),
        ],
      ),
    );
  }
}
