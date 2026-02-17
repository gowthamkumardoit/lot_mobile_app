import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/login_screen.dart';
import '../app_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _boot();
  }

  Future<void> _boot() async {
    try {
      // 🎯 Just wait for branding / animation
      await Future.delayed(const Duration(milliseconds: 1200));

      final user = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              user == null ? const LoginScreen() : const MainLayout(),
        ),
      );
    } catch (e) {
      // 🔒 Fail-safe: never block splash
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B0F2A), Color(0xFF1B0F4A), Color(0xFF2E1A7A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _controller,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.stars, color: Colors.cyanAccent, size: 72),
                SizedBox(height: 16),
                Text(
                  "LOTTERY APP",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
