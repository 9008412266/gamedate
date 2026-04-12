import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../../../../core/theme/app_theme.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;
  const VerifyEmailPage({super.key, required this.email});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _codeCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Verify Email', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) context.go('/home');
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.email_outlined, size: 64, color: AppTheme.primaryPink),
              const SizedBox(height: 16),
              Text('We sent a code to\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 32),
              TextField(
                controller: _codeCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: '000000',
                  hintStyle: TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: AppTheme.darkCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    context.read<AuthBloc>().add(VerifyEmailRequested(
                      email: widget.email,
                      code: _codeCtrl.text,
                    ));
                  },
                  child: const Text('Verify', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
