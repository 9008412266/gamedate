import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text('Save', style: TextStyle(color: AppTheme.primaryPink))),
        ],
      ),
      body: const Center(
        child: Text('Edit Profile — Coming Soon', style: TextStyle(color: Colors.white54)),
      ),
    );
  }
}
