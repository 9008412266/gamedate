import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../theme/app_theme.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/matching/presentation/pages/discover_page.dart';
import '../../features/game/presentation/pages/game_lobby_page.dart';
import '../../features/game/presentation/pages/game_room_page.dart';
import '../../features/chat/presentation/pages/chat_list_page.dart';
import '../../features/chat/presentation/pages/chat_room_page.dart';
import '../../features/chat/presentation/pages/call_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../../features/leaderboard/presentation/pages/leaderboard_page.dart';

class AppRouter {
  static GoRouter router(AuthState authState) {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final isLoggedIn = authState is AuthAuthenticated;
        final isOnAuthPage = state.matchedLocation.startsWith('/auth');
        final isSplash = state.matchedLocation == '/splash';

        if (isSplash) return null;

        if (!isLoggedIn && !isOnAuthPage) return '/auth/login';
        if (isLoggedIn && isOnAuthPage) return '/home';

        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),

        // Auth Routes
        GoRoute(
          path: '/auth',
          redirect: (_, __) => '/auth/login',
          routes: [
            GoRoute(path: 'login',    builder: (_, __) => const LoginPage()),
            GoRoute(path: 'register', builder: (_, __) => const RegisterPage()),
            GoRoute(
              path: 'verify-email',
              builder: (context, state) {
                final email = state.uri.queryParameters['email'] ?? '';
                return VerifyEmailPage(email: email);
              },
            ),
          ],
        ),

        // Main App — Shell with bottom navigation
        ShellRoute(
          builder: (context, state, child) => HomeShell(child: child),
          routes: [
            GoRoute(path: '/home',     builder: (_, __) => const HomePage()),
            GoRoute(path: '/discover', builder: (_, __) => const DiscoverPage()),
            GoRoute(
              path: '/games',
              builder: (_, __) => const GameLobbyPage(),
              routes: [
                GoRoute(
                  path: ':roomId',
                  builder: (context, state) => GameRoomPage(
                    roomId: state.pathParameters['roomId']!,
                    gameType: state.uri.queryParameters['type'] ?? 'CHESS',
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/chat',
              builder: (_, __) => const ChatListPage(),
              routes: [
                GoRoute(
                  path: ':roomId',
                  builder: (context, state) => ChatRoomPage(
                    roomId: state.pathParameters['roomId']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfilePage(),
              routes: [
                GoRoute(path: 'edit', builder: (_, __) => const EditProfilePage()),
              ],
            ),
          ],
        ),

        // Modal / Overlay Routes (no bottom nav)
        GoRoute(path: '/wallet',      builder: (_, __) => const WalletPage()),
        GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardPage()),
        GoRoute(
          path: '/call/:userId',
          builder: (context, state) => CallPage(
            targetUserId: state.pathParameters['userId']!,
            isVideo: state.uri.queryParameters['video'] == 'true',
          ),
        ),
      ],
    );
  }
}

/// Bottom navigation shell
class HomeShell extends StatefulWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  static const _routes = ['/home', '/discover', '/games', '/chat', '/profile'];

  static const _navItems = [
    {'icon': Icons.home_outlined,       'activeIcon': Icons.home_rounded,        'label': 'Home'},
    {'icon': Icons.favorite_border,     'activeIcon': Icons.favorite_rounded,     'label': 'Discover'},
    {'icon': Icons.gamepad_outlined,    'activeIcon': Icons.gamepad_rounded,      'label': 'Games'},
    {'icon': Icons.chat_bubble_outline, 'activeIcon': Icons.chat_bubble_rounded,  'label': 'Chat'},
    {'icon': Icons.person_outline,      'activeIcon': Icons.person_rounded,       'label': 'Profile'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (index) {
                final item = _navItems[index];
                final isSelected = _currentIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() => _currentIndex = index);
                    context.go(_routes[index]);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: isSelected ? BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                        color: AppTheme.primaryPink.withValues(alpha: 0.35),
                        blurRadius: 10, offset: const Offset(0, 2),
                      )],
                    ) : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected
                            ? item['activeIcon'] as IconData
                            : item['icon'] as IconData,
                          color: isSelected ? Colors.white : Colors.white38,
                          size: 22,
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          Text(item['label'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            )),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
