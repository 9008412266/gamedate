import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../../../../core/theme/app_theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _pulse;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final state = context.read<AuthBloc>().state;
    context.go(state is AuthAuthenticated ? '/home' : '/auth/login');
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D0D1A), Color(0xFF1A0A2E), Color(0xFF0D1A2E)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(top: -80, right: -80,
              child: _glowCircle(200, AppTheme.primaryPink.withOpacity(0.15))),
            Positioned(bottom: -100, left: -80,
              child: _glowCircle(250, AppTheme.primaryPurple.withOpacity(0.12))),
            Positioned(top: 200, left: -50,
              child: _glowCircle(150, AppTheme.accentCyan.withOpacity(0.08))),

            Center(
              child: FadeTransition(
                opacity: _fade,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _pulse,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryPink, AppTheme.primaryPurple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(color: AppTheme.primaryPink.withOpacity(0.4),
                                blurRadius: 30, spreadRadius: 5),
                          ],
                        ),
                        child: const Icon(Icons.gamepad_rounded, color: Colors.white, size: 52),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ShaderMask(
                      shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                      child: const Text('GameDate',
                        style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(height: 8),
                    Text('Play Together, Connect Together',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                    const SizedBox(height: 60),
                    SizedBox(
                      width: 32, height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(AppTheme.primaryPink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glowCircle(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
