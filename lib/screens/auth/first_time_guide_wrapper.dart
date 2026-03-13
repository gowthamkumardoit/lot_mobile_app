import 'package:flutter/material.dart';
import 'package:mobile_app/screens/support/how_to_play_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirstTimeGuideWrapper extends StatefulWidget {
  final Widget child;

  const FirstTimeGuideWrapper({super.key, required this.child});

  @override
  State<FirstTimeGuideWrapper> createState() => _FirstTimeGuideWrapperState();
}

class _FirstTimeGuideWrapperState extends State<FirstTimeGuideWrapper> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkGuide();
    });
  }

  Future<void> _checkGuide() async {
    final prefs = await SharedPreferences.getInstance();

    // 🔧 TEMPORARY: reset flag for testing
    // await prefs.remove("how_to_play_seen");

    final shown = prefs.getBool("how_to_play_seen") ?? false;

    if (!shown && mounted) {
      await prefs.setBool("how_to_play_seen", true);

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const HowToPlayBottomSheet(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
