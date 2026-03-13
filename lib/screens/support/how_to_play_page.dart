import 'package:flutter/material.dart';

class HowToPlayPage extends StatelessWidget {
  const HowToPlayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          "How To Play",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E1E1E),
          ),
        ),
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E1E1E)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          /// HEADER
          const Text(
            "Kuber Lottery Guide",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          _sectionTitle("Kuber Gold"),

          _infoCard(
            icon: Icons.confirmation_num,
            title: "Choose a Number",
            desc:
                "Pick a lucky number from the available digits for the current draw.",
          ),

          _infoCard(
            icon: Icons.shopping_cart,
            title: "Buy Tickets",
            desc:
                "Each number has a fixed ticket price. Purchase one or multiple tickets.",
          ),

          _infoCard(
            icon: Icons.timer,
            title: "Wait For Draw",
            desc:
                "When the draw closes, a random number is generated automatically.",
          ),

          _infoCard(
            icon: Icons.emoji_events,
            title: "Win Rewards",
            desc:
                "If your number matches the winning result, you win the jackpot reward.",
          ),

          const SizedBox(height: 30),

          _sectionTitle("Kuber X"),

          _infoCard(
            icon: Icons.flash_on,
            title: "Fast Lottery Draws",
            desc:
                "Kuber X draws run frequently throughout the day for quick results.",
          ),

          _infoCard(
            icon: Icons.local_activity,
            title: "Ticket Purchase",
            desc:
                "Ticket prices start from ₹10. You can buy multiple tickets for higher chances.",
          ),

          _infoCard(
            icon: Icons.casino,
            title: "Random Result",
            desc:
                "Once the draw closes, the system generates the winning result automatically.",
          ),

          _infoCard(
            icon: Icons.monetization_on,
            title: "Winning Payout",
            desc:
                "If your ticket matches the winning number, the prize amount is credited to your wallet.",
          ),

          const SizedBox(height: 30),

          /// IMPORTANT NOTES
          const Text(
            "Important Notes",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          _bullet("All draws close automatically at the scheduled time."),
          _bullet("Purchased tickets cannot be cancelled."),
          _bullet("Rewards are credited directly to your wallet."),
          _bullet(
            "Make sure your wallet has enough balance before purchasing.",
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFF6A3D),
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6A3D).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFFF6A3D)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
