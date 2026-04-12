import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _welcomeBanner(context),
                const SizedBox(height: 24),
                _sectionTitle('🎮 Quick Play'),
                const SizedBox(height: 12),
                _gameGrid(context),
                const SizedBox(height: 24),
                _sectionTitle('💝 Recent Matches'),
                const SizedBox(height: 12),
                _emptyCard('No matches yet', 'Start discovering players!', Icons.favorite_border),
                const SizedBox(height: 24),
                _sectionTitle('🏆 Leaderboard'),
                const SizedBox(height: 12),
                _leaderboardPreview(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      backgroundColor: AppTheme.darkSurface,
      title: ShaderMask(
        shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
        child: const Text('Playraze',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.monetization_on, color: Colors.black, size: 14),
              const SizedBox(width: 4),
              const Text('0', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
            ]),
          ),
          onPressed: () => context.push('/wallet'),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _welcomeBanner(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final name = state is AuthAuthenticated
            ? (state.user.displayName ?? state.user.username)
            : 'Player';
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A0A2E), Color(0xFF0D1A2E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryPink.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hey, $name! 👋',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Ready to play & connect?',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => context.go('/discover'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Find Players ❤️',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [BoxShadow(color: AppTheme.primaryPink.withOpacity(0.3), blurRadius: 15)],
                ),
                child: const Icon(Icons.gamepad_rounded, color: Colors.white, size: 36),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _gameGrid(BuildContext context) {
    final games = [
      {'name': 'Chess', 'emoji': '♟️', 'color': const Color(0xFF6C4AB6), 'type': 'CHESS'},
      {'name': 'Ludo', 'emoji': '🎲', 'color': const Color(0xFFFF6B9D), 'type': 'LUDO'},
    ];
    return Row(
      children: games.map((g) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: g == games.last ? 0 : 8),
          child: GestureDetector(
            onTap: () => context.go('/games'),
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: (g['color'] as Color).withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: (g['color'] as Color).withOpacity(0.4)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(g['emoji'] as String, style: const TextStyle(fontSize: 36)),
                  const SizedBox(height: 6),
                  Text(g['name'] as String,
                    style: TextStyle(color: g['color'] as Color, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('Play now', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _leaderboardPreview(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/leaderboard'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A00), Color(0xFF2A2A00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('View Top Players',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            Icon(Icons.chevron_right, color: AppTheme.accentGold),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold));

  Widget _emptyCard(String title, String subtitle, IconData icon) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppTheme.darkCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
    ),
    child: Row(
      children: [
        Icon(icon, color: Colors.white24, size: 32),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w500)),
            Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
          ],
        ),
      ],
    ),
  );
}
