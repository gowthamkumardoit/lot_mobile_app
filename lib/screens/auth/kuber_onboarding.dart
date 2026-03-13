import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KuberOnboarding extends StatefulWidget {
  const KuberOnboarding({super.key});

  @override
  State<KuberOnboarding> createState() => _KuberOnboardingState();
}

class _KuberOnboardingState extends State<KuberOnboarding> {
  final PageController _controller = PageController();
  int page = 0;

  final pages = const [
    _Slide(
      icon: Icons.tag,
      title: "Choose Lucky Number",
      desc: "Pick any number you like.\nEvery number has equal chance to win.",
    ),
    _Slide(
      icon: Icons.confirmation_num,
      title: "Buy Your Ticket",
      desc: "Use your wallet balance\nand purchase tickets instantly.",
    ),
    _Slide(
      icon: Icons.emoji_events,
      title: "Win the Jackpot",
      desc: "If your number matches the draw\nYou win big rewards!",
    ),
  ];

  Future<void> _finishOnboarding() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({"onboardingSeen": true});
    } catch (_) {}

    if (!mounted) return;
    Navigator.pop(context);
  }

  void _nextPage() {
    if (page < pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1220), Color(0xFF141B34), Color(0xFF0B1220)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              /// Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: const Text(
                    "Skip",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),

              /// Pages
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => page = i),
                  itemBuilder: (_, i) => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: pages[i],
                  ),
                ),
              ),

              /// Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.all(4),
                    width: page == i ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: page == i ? Colors.cyanAccent : Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _nextPage,
                    child: Text(
                      page == pages.length - 1 ? "Start Playing" : "Next",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _Slide({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// Icon circle
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.cyanAccent.withOpacity(0.3),
                  Colors.cyanAccent.withOpacity(0.05),
                ],
              ),
            ),
            child: Icon(icon, size: 90, color: Colors.cyanAccent),
          ),

          const SizedBox(height: 40),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
