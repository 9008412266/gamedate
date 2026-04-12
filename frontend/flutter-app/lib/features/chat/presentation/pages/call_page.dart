import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

/// Voice/Video call page (WebRTC — mobile/desktop only)
class CallPage extends StatelessWidget {
  final String targetUserId;
  final bool isVideo;

  const CallPage({super.key, required this.targetUserId, required this.isVideo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.primaryPurple,
                  child: const Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  isVideo ? 'Video Call' : 'Voice Call',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Calling...', style: TextStyle(color: Colors.white54)),
              ],
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _callBtn(Icons.mic_off, Colors.white24, () {}),
                _callBtn(Icons.call_end, Colors.red, () => context.pop(), size: 64),
                _callBtn(isVideo ? Icons.videocam_off : Icons.volume_up, Colors.white24, () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _callBtn(IconData icon, Color color, VoidCallback onTap, {double size = 50}) =>
    GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: color,
        child: Icon(icon, color: Colors.white),
      ),
    );
}
