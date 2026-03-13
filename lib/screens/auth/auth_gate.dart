import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/screens/app_shell.dart';
import 'package:mobile_app/screens/auth/first_time_guide_wrapper.dart';
import 'package:mobile_app/screens/auth/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        /// 🔄 Auth loading
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnap.data;

        /// ❌ Not logged in
        if (user == null) {
          return const LoginScreen();
        }

        /// ✅ Logged in
        return const FirstTimeGuideWrapper(child: MainLayout());
      },
    );
  }
}
