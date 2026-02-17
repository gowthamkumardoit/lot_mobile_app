import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen1 extends StatelessWidget {
  const SplashScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2E026D), // deep purple
            Color(0xFF1B0F4A), // royal blue
            Color(0xFF0B0F2A), // dark gaming bg
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// 👑 ICON
            const Text("👑", style: TextStyle(fontSize: 64))
                .animate()
                .scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1, 1),
                  curve: Curves.elasticOut,
                  duration: 800.ms,
                )
                .fadeIn(),

            const SizedBox(height: 16),

            /// 🎰 APP NAME
            Text(
                  "Lucky Raja",
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.amberAccent, blurRadius: 20),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.4, curve: Curves.easeOut),

            const SizedBox(height: 12),

            /// ✨ TAGLINE
            Text(
                  "Play Like a Raja 👑",
                  style: TextStyle(
                    fontSize: 18,
                    letterSpacing: 1.2,
                    color: Colors.white.withOpacity(0.85),
                  ),
                )
                .animate(delay: 300.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.3),

            const SizedBox(height: 40),

            /// 🎲 FUN DECOR TEXT
            Text("🎲 💎 🎯", style: const TextStyle(fontSize: 28))
                .animate(delay: 600.ms)
                .fadeIn()
                .scale(begin: const Offset(0.8, 0.8)),
          ],
        ),
      ),
    );
  }
}
