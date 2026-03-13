import 'package:flutter/material.dart';

class HowToPlayBottomSheet extends StatelessWidget {
  const HowToPlayBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Container(
      height: height * 0.8, // 👈 Normal bottom sheet height
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F6FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          /// HANDLE
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const Text(
            "How To Play",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          /// SCROLLABLE CONTENT
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// GAME PLAY
                  _step(
                    Icons.confirmation_num,
                    "Choose Number",
                    "Select your lucky number for the draw.",
                  ),

                  _step(
                    Icons.shopping_cart,
                    "Buy Tickets",
                    "Use wallet balance to purchase tickets.",
                  ),

                  _step(
                    Icons.timer,
                    "Wait for Draw",
                    "When the draw closes, the result is generated automatically.",
                  ),

                  _step(
                    Icons.emoji_events,
                    "Win Rewards",
                    "If your number matches the result, you win the prize.",
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Deposit Money (UPI / QR)",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  _bullet("Go to Wallet → Add Money"),
                  _bullet("Enter deposit amount"),
                  _bullet("Pay via UPI ID or scan QR"),
                  _bullet("Submit payment reference"),
                  _bullet("Amount will be credited after verification"),

                  const SizedBox(height: 20),

                  const Text(
                    "Withdraw Money",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  _bullet("Complete KYC verification"),
                  _bullet("Add your UPI ID"),
                  _bullet("Enter withdrawal amount"),
                  _bullet("Submit withdrawal request"),
                  _bullet("Amount will be transferred to your UPI"),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          /// CONTINUE BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6A3D),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Continue",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF6A3D)),
          const SizedBox(width: 10),
          Expanded(
            child: Text("$title — $desc", style: const TextStyle(fontSize: 14)),
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
