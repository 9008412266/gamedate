import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class ChatRoomPage extends StatefulWidget {
  final String roomId;
  const ChatRoomPage({super.key, required this.roomId});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _messages = [
    {'sender': 'them', 'text': 'Hey! Good game earlier 🎮', 'time': '2:30 PM'},
    {'sender': 'me', 'text': 'Thanks! You played really well', 'time': '2:31 PM'},
    {'sender': 'them', 'text': 'Rematch tonight? ♟️', 'time': '2:31 PM'},
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: const Center(child: Text('♟️', style: TextStyle(fontSize: 18))),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF44FF88),
                      border: Border.all(color: AppTheme.darkSurface, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.roomId.isEmpty ? 'Player' : widget.roomId,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                const Text('Online', style: TextStyle(color: Color(0xFF44FF88), fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.videocam_outlined, color: AppTheme.accentCyan, size: 22),
            onPressed: () => context.push('/call/${widget.roomId}?video=true'),
          ),
          IconButton(
            icon: Icon(Icons.call_outlined, color: AppTheme.primaryPink, size: 22),
            onPressed: () => context.push('/call/${widget.roomId}?video=false'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('👋', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text('Say hello!',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _bubble(_messages[i]),
                ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _bubble(Map<String, dynamic> msg) {
    final isMe = msg['sender'] == 'me';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMe ? AppTheme.primaryGradient : null,
                color: isMe ? null : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: isMe ? [BoxShadow(
                  color: AppTheme.primaryPink.withOpacity(0.2),
                  blurRadius: 8, offset: const Offset(0, 2),
                )] : null,
              ),
              child: Text(msg['text'] as String,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
            ),
            const SizedBox(height: 2),
            Text(msg['time'] as String,
              style: TextStyle(color: Colors.white.withOpacity(0.28), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _inputBar() => Container(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
    decoration: BoxDecoration(
      color: AppTheme.darkSurface,
      border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
    ),
    child: Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: TextField(
              controller: _msgCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                prefixIcon: Icon(Icons.emoji_emotions_outlined,
                  color: Colors.white.withOpacity(0.3), size: 20),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _send,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: AppTheme.primaryPink.withOpacity(0.3),
                blurRadius: 10, offset: const Offset(0, 2),
              )],
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
          ),
        ),
      ],
    ),
  );

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'sender': 'me', 'text': text, 'time': 'Now'});
      _msgCtrl.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
