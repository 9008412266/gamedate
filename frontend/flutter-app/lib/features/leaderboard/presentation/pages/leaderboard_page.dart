import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  static const _players = [
    {'name': 'NightOwl', 'rating': 2840, 'wins': 312, 'emoji': '🦉', 'streak': 15},
    {'name': 'PixelKing', 'rating': 2720, 'wins': 287, 'emoji': '👑', 'streak': 8},
    {'name': 'StarGazer', 'rating': 2650, 'wins': 261, 'emoji': '⭐', 'streak': 12},
    {'name': 'IronWall', 'rating': 2580, 'wins': 243, 'emoji': '🛡️', 'streak': 6},
    {'name': 'ThunderBolt', 'rating': 2490, 'wins': 218, 'emoji': '⚡', 'streak': 3},
    {'name': 'MoonRider', 'rating': 2410, 'wins': 195, 'emoji': '🌙', 'streak': 9},
    {'name': 'You', 'rating': 1200, 'wins': 0, 'emoji': '🎮', 'streak': 0, 'isMe': true},
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.darkSurface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              onPressed: () => context.pop(),
            ),
            title: ShaderMask(
              shaderCallback: (b) => AppTheme.goldGradient.createShader(b),
              child: const Text('Leaderboard',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: AppTheme.accentGold,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: AppTheme.accentGold,
              unselectedLabelColor: Colors.white38,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Global'),
                Tab(text: 'Chess'),
                Tab(text: 'Ludo'),
              ],
            ),
          ),

          SliverToBoxAdapter(child: _podium()),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final p = _players[i + 3];
                  final rank = i + 4;
                  final isMe = (p['isMe'] as bool?) ?? false;
                  return _rankTile(p, rank, isMe);
                },
                childCount: _players.length - 3,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _podium() {
    final top3 = _players.take(3).toList();
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1400), Color(0xFF2A2200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _podiumSlot(top3[1], 2, 80),
              _podiumSlot(top3[0], 1, 100),
              _podiumSlot(top3[2], 3, 68),
            ],
          ),
        ],
      ),
    );
  }

  Widget _podiumSlot(Map<String, dynamic> player, int rank, double size) {
    final colors = {
      1: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      2: [const Color(0xFFC0C0C0), const Color(0xFF808080)],
      3: [const Color(0xFFCD7F32), const Color(0xFF8B5A2B)],
    };
    final c = colors[rank]!;
    final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉';

    return Column(
      children: [
        if (rank == 1) ...[
          const Text('👑', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
        ],
        Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: c),
            boxShadow: [BoxShadow(color: c[0].withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 2)],
          ),
          child: Center(child: Text(player['emoji'] as String,
            style: TextStyle(fontSize: size * 0.42))),
        ),
        const SizedBox(height: 8),
        Text(player['name'] as String,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        Text('${player['rating']}', style: TextStyle(color: c[0], fontSize: 12, fontWeight: FontWeight.w600)),
        Text(medal, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _rankTile(Map<String, dynamic> player, int rank, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? AppTheme.primaryPink.withValues(alpha: 0.12) : AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? AppTheme.primaryPink.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('#$rank',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              )),
          ),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isMe ? AppTheme.primaryGradient : null,
              color: isMe ? null : Colors.white.withValues(alpha: 0.08),
            ),
            child: Center(child: Text(player['emoji'] as String, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(player['name'] as String,
                      style: TextStyle(
                        color: isMe ? AppTheme.primaryPink : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      )),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPink.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('You', style: TextStyle(color: AppTheme.primaryPink, fontSize: 10)),
                      ),
                    ],
                  ],
                ),
                Text('${player['wins']} wins',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${player['rating']}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Color(0xFFFF6B35), size: 13),
                  Text('${player['streak']}',
                    style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
