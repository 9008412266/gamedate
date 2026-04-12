import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../../../../core/theme/app_theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  bool _obscure = true;
  int _age = 22;
  late AnimationController _animCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _animCtrl.dispose();
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
            Positioned(top: -60, left: -60,
              child: _glowCircle(180, AppTheme.primaryPurple.withValues(alpha: 0.12))),
            Positioned(bottom: -80, right: -60,
              child: _glowCircle(200, AppTheme.primaryPink.withValues(alpha: 0.1))),
            SafeArea(
              child: BlocListener<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthEmailVerificationRequired) {
                    context.go('/auth/verify-email?email=${state.email}');
                  } else if (state is AuthError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message), backgroundColor: AppTheme.error,
                        behavior: SnackBarBehavior.floating),
                    );
                  }
                },
                child: FadeTransition(
                  opacity: _fade,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                              onPressed: () => context.pop(),
                            ),
                            const SizedBox(width: 4),
                            ShaderMask(
                              shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                              child: const Text('Create Account',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text('Join the community',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13)),
                              const SizedBox(height: 28),
                              _buildField(
                                ctrl: _usernameCtrl,
                                label: 'Username',
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 14),
                              _buildField(
                                ctrl: _emailCtrl,
                                label: 'Email address',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 14),
                              _buildField(
                                ctrl: _passwordCtrl,
                                label: 'Password',
                                icon: Icons.lock_outline,
                                obscure: _obscure,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: Colors.white38, size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildField(
                                ctrl: _phoneCtrl,
                                label: 'Phone Number',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.cake_outlined, color: Colors.white38, size: 20),
                                        const SizedBox(width: 10),
                                        Text('Age', style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 14)),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            gradient: AppTheme.primaryGradient,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text('$_age', style: const TextStyle(
                                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                        ),
                                      ],
                                    ),
                                    Slider(
                                      value: _age.toDouble(),
                                      min: 18, max: 60,
                                      activeColor: AppTheme.primaryPink,
                                      inactiveColor: Colors.white12,
                                      onChanged: (v) => setState(() => _age = v.toInt()),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  if (state is AuthLoading) {
                                    return Container(
                                      height: 52,
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.primaryGradient,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                      ),
                                    );
                                  }
                                  return GestureDetector(
                                    onTap: () => context.read<AuthBloc>().add(RegisterRequested(
                                      username: _usernameCtrl.text,
                                      email: _emailCtrl.text,
                                      password: _passwordCtrl.text,
                                      phoneNumber: _phoneCtrl.text,
                                      age: _age,
                                    )),
                                    child: Container(
                                      height: 52,
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.primaryGradient,
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [BoxShadow(
                                          color: AppTheme.primaryPink.withValues(alpha: 0.35),
                                          blurRadius: 16, offset: const Offset(0, 6),
                                        )],
                                      ),
                                      child: const Center(
                                        child: Text('Create Account',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Already have an account? ',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 14)),
                                    GestureDetector(
                                      onTap: () => context.pop(),
                                      child: const Text('Sign In',
                                        style: TextStyle(
                                          color: AppTheme.primaryPink,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        )),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.primaryPink.withValues(alpha: 0.7), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _glowCircle(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
