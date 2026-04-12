import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

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
              child: const Text('Wallet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded, color: Colors.white70),
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Balance card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A1400), Color(0xFF2A2200), Color(0xFF1A1A00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.accentGold.withOpacity(0.35)),
                      boxShadow: [BoxShadow(
                        color: AppTheme.accentGold.withOpacity(0.15),
                        blurRadius: 24, spreadRadius: 2,
                      )],
                    ),
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (b) => AppTheme.goldGradient.createShader(b),
                          child: const Icon(Icons.monetization_on, color: Colors.white, size: 44),
                        ),
                        const SizedBox(height: 12),
                        Text('Coin Balance',
                          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13)),
                        const SizedBox(height: 8),
                        ShaderMask(
                          shaderCallback: (b) => AppTheme.goldGradient.createShader(b),
                          child: const Text('0',
                            style: TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.bold)),
                        ),
                        Text('coins', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13)),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _miniStat('Earned', '0'),
                            Container(width: 1, height: 30, color: Colors.white12),
                            _miniStat('Spent', '0'),
                            Container(width: 1, height: 30, color: Colors.white12),
                            _miniStat('Streak', '0d'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Subscription banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(
                        color: AppTheme.primaryPink.withOpacity(0.3),
                        blurRadius: 16, offset: const Offset(0, 4),
                      )],
                    ),
                    child: Row(
                      children: [
                        const Text('👑', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Playraze Premium',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              Text('Unlimited likes, boosts & more',
                                style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Upgrade',
                            style: TextStyle(
                              color: AppTheme.primaryPink,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            )),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Earn methods
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Earn Coins',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  _earnCard(
                    icon: Icons.videogame_asset_rounded,
                    color: AppTheme.primaryPink,
                    title: 'Play & Earn',
                    subtitle: 'Win games to earn coins',
                    reward: '+50',
                    onTap: () => context.go('/games'),
                  ),
                  const SizedBox(height: 10),
                  _earnCard(
                    icon: Icons.calendar_today_rounded,
                    color: AppTheme.accentGold,
                    title: 'Daily Reward',
                    subtitle: 'Claim your daily bonus',
                    reward: '+10',
                    badge: 'Ready',
                    onTap: () {},
                  ),
                  const SizedBox(height: 10),
                  _earnCard(
                    icon: Icons.play_circle_outline_rounded,
                    color: AppTheme.accentCyan,
                    title: 'Watch Ad',
                    subtitle: 'Watch a short video',
                    reward: '+5',
                    onTap: () {},
                  ),
                  const SizedBox(height: 10),
                  _earnCard(
                    icon: Icons.person_add_outlined,
                    color: AppTheme.primaryPurple,
                    title: 'Invite Friends',
                    subtitle: 'Earn 100 coins per referral',
                    reward: '+100',
                    onTap: () {},
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) => Column(
    children: [
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11)),
    ],
  );

  Widget _earnCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String reward,
    String? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF44FF88).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(badge,
                            style: const TextStyle(color: Color(0xFF44FF88), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(reward, style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
