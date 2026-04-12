import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/theme/app_theme.dart';

/// Animated overlay shown when two users match.
class MatchOverlay extends StatefulWidget {
  final Map<String, dynamic> matchedUser;
  final VoidCallback onClose;

  const MatchOverlay({
    super.key,
    required this.matchedUser,
    required this.onClose,
  });

  @override
  State<MatchOverlay> createState() => _MatchOverlayState();
}

class _MatchOverlayState extends State<MatchOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnimation = CurvedAnimation(
        parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryPurple.withOpacity(0.95),
              AppTheme.primaryPink.withOpacity(0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Confetti animation
              SizedBox(
                height: 150,
                child: Lottie.asset('assets/animations/confetti.json',
                    repeat: true),
              ),

              // Match text
              ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  children: [
                    const Text('💕', style: TextStyle(fontSize: 60)),
                    const SizedBox(height: 8),
                    const Text(
                      "It's a Match!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You and ${widget.matchedUser['displayName']} liked each other!',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // User photos
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Current user
                  _UserAvatar(photoUrl: null, label: 'You'),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('❤️', style: TextStyle(fontSize: 32)),
                  ),
                  // Matched user
                  _UserAvatar(
                    photoUrl: widget.matchedUser['profilePhotoUrl'],
                    label: widget.matchedUser['displayName'],
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    // Send message button
                    ElevatedButton.icon(
                      onPressed: () {
                        widget.onClose();
                        context.push(
                            '/chat/${widget.matchedUser['chatRoomId']}');
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Send a Message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryPink,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Challenge to game button
                    OutlinedButton.icon(
                      onPressed: () {
                        widget.onClose();
                        context.push('/games?invite=${widget.matchedUser['userId']}');
                      },
                      icon: const Icon(Icons.gamepad_outlined),
                      label: const Text('Challenge to a Game'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Keep swiping
                    TextButton(
                      onPressed: widget.onClose,
                      child: Text('Keep Swiping',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.6))),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String label;

  const _UserAvatar({this.photoUrl, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: ClipOval(
            child: photoUrl != null
                ? CachedNetworkImage(imageUrl: photoUrl!, fit: BoxFit.cover)
                : Container(
                    color: AppTheme.darkCard,
                    child: const Icon(Icons.person, color: Colors.white, size: 44),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
