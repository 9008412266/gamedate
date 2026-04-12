import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  // Demo data for visual preview
  static const List<Map<String, dynamic>> _demoChats = [
    {'name': 'Alex', 'msg': 'Good game! Rematch?', 'time': '2m', 'unread': 2, 'emoji': '♟️', 'online': true},
    {'name': 'Jordan', 'msg': 'gg wp! That was close', 'time': '15m', 'unread': 0, 'emoji': '🎲', 'online': true},
    {'name': 'Sam', 'msg': 'You free tonight?', 'time': '1h', 'unread': 1, 'emoji': '🎮', 'online': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppTheme.darkSurface,
            title: ShaderMask(
              shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
              child: const Text('Messages',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white70),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _onlineRow(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Recent', style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _chatTile(context, _demoChats[i]),
              childCount: _demoChats.length,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 48, color: Colors.white.withValues(alpha: 0.1)),
                    const SizedBox(height: 12),
                    Text('Match with more players to chat!',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _onlineRow(BuildContext context) {
    final onlinePlayers = [
      {'emoji': '♟️', 'name': 'Alex'},
      {'emoji': '🎲', 'name': 'Jordan'},
      {'emoji': '🎮', 'name': 'Riley'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Online Now', style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: onlinePlayers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final p = onlinePlayers[i];
              return Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.primaryGradient,
                          border: Border.all(color: AppTheme.darkBg, width: 2),
                        ),
                        child: Center(child: Text(p['emoji']!, style: const TextStyle(fontSize: 22))),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF44FF88),
                            border: Border.all(color: AppTheme.darkBg, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(p['name']!, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _chatTile(BuildContext context, Map<String, dynamic> chat) {
    final hasUnread = (chat['unread'] as int) > 0;
    return InkWell(
      onTap: () => context.push('/chat/${chat['name'].toLowerCase()}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: Center(child: Text(chat['emoji'] as String, style: const TextStyle(fontSize: 24))),
                ),
                if (chat['online'] as bool)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 13, height: 13,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF44FF88),
                        border: Border.all(color: AppTheme.darkBg, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(chat['name'] as String,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                      const Spacer(),
                      Text(chat['time'] as String,
                        style: TextStyle(
                          color: hasUnread ? AppTheme.primaryPink : Colors.white38,
                          fontSize: 12,
                        )),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(chat['msg'] as String,
                          style: TextStyle(
                            color: hasUnread ? Colors.white60 : Colors.white38,
                            fontSize: 13,
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis),
                      ),
                      if (hasUnread)
                        Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('${chat['unread']}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
