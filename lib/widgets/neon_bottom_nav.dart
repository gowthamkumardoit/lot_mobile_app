import 'package:flutter/material.dart';

class NeonBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const NeonBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1028),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.25),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Colors.cyanAccent,
        unselectedItemColor: Colors.white38,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 12)],
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_num_rounded),
            label: 'Tickets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: "Wallet",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
