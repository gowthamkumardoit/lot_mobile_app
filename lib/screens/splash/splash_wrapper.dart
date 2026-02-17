import 'package:flutter/material.dart';
import 'package:mobile_app/screens/splash/splash_screen_1.dart';
import 'package:mobile_app/screens/splash/splash_screen_2.dart';
import 'package:mobile_app/screens/auth/login_screen.dart';

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  final PageController _controller = PageController();
  int _currentIndex = 0;
  bool _navigated = false;

  final int totalPages = 2;

  @override
  void initState() {
    super.initState();
    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    for (int i = 1; i < totalPages; i++) {
      await _controller.animateToPage(
        i,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _currentIndex = i;
      if (!mounted) return;
      setState(() {});
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  void goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              if (mounted) {
                setState(() => _currentIndex = index);
              }
            },
            children: const [SplashScreen1(), SplashScreen2()],
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 20,
            child: TextButton(
              onPressed: goNext,
              child: const Text(
                "SKIP",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DotsIndicator(count: totalPages, index: _currentIndex),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: goNext,
                      child: Text(
                        _currentIndex == totalPages - 1
                            ? "GET STARTED"
                            : "NEXT",
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DotsIndicator extends StatelessWidget {
  final int count;
  final int index;

  const DotsIndicator({super.key, required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == i ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: index == i ? Colors.white : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
