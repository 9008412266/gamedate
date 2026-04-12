import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/gradient_button.dart';
import '../widgets/social_login_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
            Positioned(top: -60, right: -60,
              child: _glowCircle(200, AppTheme.primaryPink.withOpacity(0.12))),
            Positioned(bottom: -80, left: -60,
              child: _glowCircle(220, AppTheme.primaryPurple.withOpacity(0.1))),
            SafeArea(
              child: BlocListener<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthAuthenticated) context.go('/home');
                  else if (state is AuthError) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppTheme.error,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 48),
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 72, height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppTheme.primaryGradient,
                                    boxShadow: [BoxShadow(
                                      color: AppTheme.primaryPink.withOpacity(0.4),
                                      blurRadius: 24, spreadRadius: 2,
                                    )],
                                  ),
                                  child: const Icon(Icons.gamepad_rounded, color: Colors.white, size: 38),
                                ),
                                const SizedBox(height: 16),
                                ShaderMask(
                                  shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                                  child: const Text('Playraze',
                                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                                const SizedBox(height: 6),
                                Text('Play Together, Connect Together',
                                  style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 44),
                          const Text('Welcome Back!',
                            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('Sign in to continue playing',
                            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13)),
                          const SizedBox(height: 32),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildField(
                                  controller: _emailController,
                                  label: 'Email or Username',
                                  icon: Icons.person_outline,
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 16),
                                _buildField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                  obscure: _obscurePassword,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      color: Colors.white38, size: 20,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => context.push('/auth/forgot-password'),
                                    child: Text('Forgot Password?',
                                      style: TextStyle(color: AppTheme.primaryPink, fontSize: 13)),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                BlocBuilder<AuthBloc, AuthState>(
                                  builder: (context, state) => GradientButton(
                                    text: 'Sign In',
                                    isLoading: state is AuthLoading,
                                    onPressed: _submit,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white.withOpacity(0.12))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('or', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13)),
                              ),
                              Expanded(child: Divider(color: Colors.white.withOpacity(0.12))),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SocialLoginButton(
                            text: 'Continue with Google',
                            iconPath: 'assets/icons/google.svg',
                            onPressed: () => context.read<AuthBloc>().add(GoogleSignInRequested()),
                          ),
                          const SizedBox(height: 12),
                          SocialLoginButton(
                            text: 'Continue with Apple',
                            iconPath: 'assets/icons/apple.svg',
                            onPressed: () => context.read<AuthBloc>().add(AppleSignInRequested()),
                          ),
                          const SizedBox(height: 36),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Don't have an account? ",
                                  style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14)),
                                GestureDetector(
                                  onTap: () => context.push('/auth/register'),
                                  child: const Text('Sign Up',
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.primaryPink.withOpacity(0.7), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _glowCircle(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(LoginRequested(
        emailOrUsername: _emailController.text.trim(),
        password: _passwordController.text,
      ));
    }
  }
}
