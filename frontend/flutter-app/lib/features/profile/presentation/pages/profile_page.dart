import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is AuthAuthenticated ? state.user : null;
          final name = user?.displayName ?? user?.username ?? 'Player';
          final username = user?.username ?? 'username';
          final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: AppTheme.darkSurface,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A0A2E), Color(0xFF0D1A2E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(top: -40, right: -40,
                          child: _glowCircle(160, AppTheme.primaryPink.withOpacity(0.12))),
                        Positioned(bottom: -30, left: -30,
                          child: _glowCircle(120, AppTheme.primaryPurple.withOpacity(0.1))),
                        Positioned.fill(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 32),
                              Container(
                                width: 88, height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppTheme.primaryGradient,
                                  boxShadow: [BoxShadow(
                                    color: AppTheme.primaryPink.withOpacity(0.4),
                                    blurRadius: 20, spreadRadius: 2,
                                  )],
                                ),
                                child: Center(
                                  child: Text(initial,
                                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(name, style: const TextStyle(
                                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('@$username', style: TextStyle(
                                color: Colors.white.withOpacity(0.5), fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                    ),
                    onPressed: () => context.push('/profile/edit'),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Stats row
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.darkSurface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withOpacity(0.07)),
                        ),
                        child: Row(
                          children: [
                            _stat('Games', '0', Icons.gamepad_outlined, AppTheme.accentCyan),
                            _divider(),
                            _stat('Wins', '0', Icons.emoji_events_outlined, AppTheme.accentGold),
                            _divider(),
                            _stat('Rating', '1200', Icons.star_outline, AppTheme.primaryPink),
                            _divider(),
                            _stat('Matches', '0', Icons.favorite_outline, const Color(0xFFFF6B9D)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Games section
                      _sectionHeader('Favorite Games'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _gameChip('♟️', 'Chess', AppTheme.primaryPurple)),
                          const SizedBox(width: 10),
                          Expanded(child: _gameChip('🎲', 'Ludo', AppTheme.primaryPink)),
                          const SizedBox(width: 10),
                          Expanded(child: _gameChip('➕', 'More', Colors.white24)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Menu
                      _sectionHeader('Account'),
                      const SizedBox(height: 12),
                      _menuCard([
                        _menuItem(context, Icons.account_balance_wallet_outlined, 'Wallet', AppTheme.accentGold,
                            () => context.push('/wallet')),
                        _dividerLine(),
                        _menuItem(context, Icons.leaderboard_outlined, 'Leaderboard', AppTheme.primaryPink,
                            () => context.push('/leaderboard')),
                        _dividerLine(),
                        _menuItem(context, Icons.settings_outlined, 'Settings', Colors.white54, () {}),
                      ]),
                      const SizedBox(height: 12),
                      _menuCard([
                        _menuItem(context, Icons.logout, 'Logout', const Color(0xFFFF4444), () {
                          context.read<AuthBloc>().add(LogoutRequested());
                        }),
                      ]),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    ),
  );

  Widget _divider() => Container(width: 1, height: 40, color: Colors.white.withOpacity(0.08));

  Widget _sectionHeader(String title) => Align(
    alignment: Alignment.centerLeft,
    child: Text(title, style: const TextStyle(
      color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
  );

  Widget _gameChip(String emoji, String name, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(name, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _menuCard(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: AppTheme.darkSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.07)),
    ),
    child: Column(children: children),
  );

  Widget _menuItem(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) =>
    InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15))),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );

  Widget _dividerLine() => Divider(height: 1, indent: 56, color: Colors.white.withOpacity(0.06));

  Widget _glowCircle(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
