import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/game_bloc.dart';

class GameLobbyPage extends StatelessWidget {
  const GameLobbyPage({super.key});

  static const _games = [
    {'id': 'CHESS',    'name': 'Chess',     'icon': '♟️', 'desc': '2 players • Strategy',       'color': 0xFF9B59B6},
    {'id': 'LUDO',     'name': 'Ludo',      'icon': '🎲', 'desc': '2-4 players • Family fun',   'color': 0xFFE74C3C},
    {'id': 'BILLIARDS','name': 'Billiards', 'icon': '🎱', 'desc': '2 players • Skill game',      'color': 0xFF27AE60},
    {'id': 'CARROM',   'name': 'Carrom',    'icon': '🎯', 'desc': '2-4 players • Board game',   'color': 0xFFF39C12},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Games 🎮'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            onPressed: () => context.push('/leaderboard'),
          ),
        ],
      ),
      body: BlocListener<GameBloc, GameState>(
        listener: (context, state) {
          if (state is GameRoomActive) {
            context.push('/games/${state.gameState['roomId']}?type=${state.gameState['gameType']}');
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Daily limit banner
              _DailyLimitBanner(),
              const SizedBox(height: 20),

              // Game grid
              const Text('Choose a Game',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: _games.length,
                itemBuilder: (context, i) => _GameCard(game: _games[i]),
              ),

              const SizedBox(height: 24),

              // Quick Play section
              const Text('Quick Play vs AI',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              Row(
                children: ['EASY', 'MEDIUM', 'HARD'].map((difficulty) =>
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _AiDifficultyCard(difficulty: difficulty),
                    ),
                  ),
                ).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final Map<String, dynamic> game;
  const _GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showGameOptions(context),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(game['color'] as int),
              Color(game['color'] as int).withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color(game['color'] as int).withOpacity(0.3),
              blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(game['icon'] as String,
                  style: const TextStyle(fontSize: 40)),
              const Spacer(),
              Text(game['name'] as String,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(game['desc'] as String,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  void _showGameOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _GameOptionsSheet(game: game),
    );
  }
}

class _GameOptionsSheet extends StatelessWidget {
  final Map<String, dynamic> game;
  const _GameOptionsSheet({required this.game});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${game['icon']} ${game['name']}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          _OptionTile(
            icon: Icons.people_outline,
            title: 'Find a Match',
            subtitle: 'Play with a random player nearby',
            onTap: () {
              Navigator.pop(context);
              context.read<GameBloc>().add(CreateGameRoom(gameType: game['id'] as String));
            },
          ),

          _OptionTile(
            icon: Icons.smart_toy_outlined,
            title: 'vs AI',
            subtitle: 'Play against the computer',
            onTap: () {
              Navigator.pop(context);
              _showAiDifficultyPicker(context);
            },
          ),

          _OptionTile(
            icon: Icons.link_outlined,
            title: 'Invite a Friend',
            subtitle: 'Share a private room link',
            onTap: () {
              Navigator.pop(context);
              // TODO: Create private room and share invite
            },
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showAiDifficultyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['EASY', 'MEDIUM', 'HARD'].map((d) => ListTile(
            title: Text(d),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              context.read<GameBloc>().add(CreateGameRoom(
                gameType: game['id'] as String,
                aiDifficulty: d,
              ));
            },
          )).toList(),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon, required this.title,
    required this.subtitle, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: AppTheme.primaryPink.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppTheme.primaryPink),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5))),
      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
      onTap: onTap,
    );
  }
}

class _AiDifficultyCard extends StatelessWidget {
  final String difficulty;
  const _AiDifficultyCard({required this.difficulty});

  Color get _color => switch (difficulty) {
    'EASY'   => AppTheme.success,
    'MEDIUM' => AppTheme.warning,
    'HARD'   => AppTheme.error,
    _        => AppTheme.primaryPink,
  };

  String get _emoji => switch (difficulty) {
    'EASY'   => '🤖',
    'MEDIUM' => '🧠',
    'HARD'   => '💀',
    _        => '🎮',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showGamePicker(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Text(_emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(difficulty,
                style: TextStyle(
                  color: _color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showGamePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$_emoji $difficulty Mode', style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...['CHESS', 'LUDO', 'BILLIARDS'].map((game) => ListTile(
              title: Text(game),
              onTap: () {
                Navigator.pop(context);
                context.read<GameBloc>().add(CreateGameRoom(
                  gameType: game, aiDifficulty: difficulty));
              },
            )),
          ],
        ),
      ),
    );
  }
}

class _DailyLimitBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🎮', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('5 Free Games Today',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Watch an ad for +1 free game',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {}, // Show rewarded ad
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('+1', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
