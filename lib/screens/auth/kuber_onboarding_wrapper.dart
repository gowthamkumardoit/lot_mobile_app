import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'kuber_onboarding.dart';

class KuberOnboardingWrapper extends StatefulWidget {
  final Widget child;

  const KuberOnboardingWrapper({super.key, required this.child});

  @override
  State<KuberOnboardingWrapper> createState() => _KuberOnboardingWrapperState();
}

class _KuberOnboardingWrapperState extends State<KuberOnboardingWrapper> {
  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    final shown = prefs.getBool("kuber_onboarding_seen") ?? false;

    if (!shown && mounted) {
      await prefs.setBool("kuber_onboarding_seen", true);

      Future.delayed(const Duration(milliseconds: 400), () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KuberOnboarding()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
