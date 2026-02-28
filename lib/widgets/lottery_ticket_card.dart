import 'package:flutter/material.dart';

class LotteryTicketCard extends StatelessWidget {
  final String type;
  final String number;
  final int amount;
  final int winAmount;
  final String date;
  final String status;
  final String drawName;
  final String? winningNumber;

  const LotteryTicketCard({
    super.key,
    required this.type,
    required this.number,
    required this.amount,
    required this.winAmount,
    required this.date,
    required this.status,
    required this.drawName,
    required this.winningNumber,
  });

  Color get accent {
    switch (type) {
      case "2D":
        return const Color(0xFFFF6A00); // orange
      case "3D":
        return const Color(0xFF6A1B9A); // deep violet
      case "4D":
        return const Color(0xFFD4A017); // gold
      default:
        return const Color(0xFFFF6A00);
    }
  }

  Color get lightAccent => accent.withOpacity(0.08);

  @override
  Widget build(BuildContext context) {
    final bool isResultDeclared = status == "WON" || status == "LOST";

    return Container(
      decoration: BoxDecoration(
        color: lightAccent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.30), width: 1),
      ),
      child: Column(
        children: [
          /// Slim Accent Strip
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Top Row
                Row(children: [_typeBadge(), const Spacer(), _statusChip()]),

                const SizedBox(height: 10),

                /// Number + Bet Amount
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        number,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                          color: accent,
                        ),
                      ),
                    ),
                    Text(
                      "₹$amount",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2A2A2A),
                      ),
                    ),
                  ],
                ),

                /// 🎯 Show Winning Number (if declared)
                if (isResultDeclared && winningNumber != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        "Winning Number: ",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF555555),
                        ),
                      ),
                      Text(
                        winningNumber!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: status == "WON" ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],

                /// 💰 Show Win Amount (if WON)
                if (status == "WON" && winAmount > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text(
                        "You Won: ",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF555555),
                        ),
                      ),
                      Text(
                        "₹$winAmount",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 8),

                Divider(
                  height: 14,
                  thickness: 0.8,
                  color: accent.withOpacity(0.25),
                ),

                /// Draw + Date
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        drawName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2A2A2A),
                        ),
                      ),
                    ),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _statusChip() {
    Color color;
    switch (status) {
      case "WON":
        color = Colors.green;
        break;
      case "LOST":
        color = Colors.red;
        break;
      case "PENDING":
        color = const Color(0xFFFF6A00);
        break;
      default:
        color = const Color(0xFF777777);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
