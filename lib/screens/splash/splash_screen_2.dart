import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

class SplashScreen2 extends StatelessWidget {
  const SplashScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0B0F2A), // dark gaming bg
            Color(0xFF1B0F4A), // royal blue
            Color(0xFF2E026D), // deep purple
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// 🎆 CONFETTI
            Animate(
              effects: [
                FadeEffect(duration: 600.ms),
                ScaleEffect(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                ),
              ],
              child: Lottie.asset(
                'assets/lottie/confetti.json',
                width: 220,
                repeat: true,
              ),
            ),

            const SizedBox(height: 24),

            /// 🏆 MAIN TEXT
            Text(
                  "WIN BIG",
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.amberAccent, blurRadius: 24),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 700.ms)
                .slideY(begin: 0.4, curve: Curves.easeOut),

            const SizedBox(height: 14),

            /// ✨ SUBTEXT
            Text(
                  "Instant results • Real rewards 💰",
                  style: TextStyle(
                    fontSize: 18,
                    letterSpacing: 0.8,
                    color: Colors.white.withOpacity(0.85),
                  ),
                  textAlign: TextAlign.center,
                )
                .animate(delay: 300.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.3),

            const SizedBox(height: 40),

            /// 🎰 FUN ICON ROW
            Text("🎰 💎 👑", style: const TextStyle(fontSize: 30))
                .animate(delay: 600.ms)
                .fadeIn()
                .scale(begin: const Offset(0.8, 0.8)),
          ],
        ),
      ),
    );
  }
}
