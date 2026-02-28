import 'package:flutter/material.dart';
import 'package:mobile_app/services/draw_result_service.dart';
import '../screens/home/home_page.dart';
import '../screens/tickets/tickets_page.dart';
import '../screens/history/history_page.dart';
import '../screens//wallet/wallet_page.dart';
import '../screens/profile/profile_page.dart';
import 'package:mobile_app/services/push_notification_service.dart';
import 'package:mobile_app/widgets/game_bottom_nav.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  static _MainLayoutState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MainLayoutState>();
  }

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _index = 0;

  @override
  void initState() {
    super.initState();

    // 🔔 INIT PUSH NOTIFICATIONS AFTER LOGIN
    PushNotificationService.init();
  }

  void setTab(int index) {
    setState(() {
      _index = index;
    });
    if (index == 2) {
      DrawResultService.clearCache();
    }
  }

  final pages = [
    const HomePage(),
    const TicketsPage(),
    HistoryPage(key: UniqueKey()), // ✅ NOT const
    const WalletPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,

      body: IndexedStack(index: _index, children: pages),

      bottomNavigationBar: GameBottomNav(currentIndex: _index, onTap: setTab),
    );
  }
}
