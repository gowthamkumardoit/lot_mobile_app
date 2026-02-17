import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:mobile_app/main.dart';
import 'package:mobile_app/screens/home/home_page.dart';
import 'package:mobile_app/screens/history/history_page.dart';
import 'package:mobile_app/screens/support/telegram_support_page.dart';
import 'package:mobile_app/screens/wallet/wallet_page.dart';
import 'package:mobile_app/screens/profile/profile_page.dart';

class NotificationRouter {
  static void handle(RemoteMessage message) {
    final data = message.data;

    final screen = data['screen'];
    final action = data['action'];
    final id = data['id'];

    final nav = navigatorKey.currentState;
    if (nav == null) return;

    switch (screen) {
      /* ---------------- SUPPORT ---------------- */
      case 'support':
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SupportScreen()),
          (_) => false,
        );
        break;

      /* ---------------- WALLET ---------------- */
      case 'wallet':
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WalletPage()),
          (_) => false,
        );
        break;

      /* ---------------- PROFILE ---------------- */
      case 'profile':
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ProfilePage()),
          (_) => false,
        );
        break;

      /* ---------------- HISTORY / TICKETS ---------------- */
      case 'history':
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HistoryPage()),
          (_) => false,
        );
        break;

      /* ---------------- HOME (DEFAULT) ---------------- */
      case 'home':
      default:
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
        );
        break;
    }
  }
}
