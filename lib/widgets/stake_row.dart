import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StakeRow extends StatelessWidget {
  final String number;
  final int stake;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;

  const StakeRow({
    super.key,
    required this.number,
    required this.stake,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final glow = stake > 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: glow ? const Color(0xFF0B2E3A) : Colors.white.withOpacity(0.08),
        border: Border.all(
          color: glow ? Colors.cyanAccent : Colors.white24,
          width: glow ? 1.2 : 1,
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.6),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),

          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
            onPressed: () {
              HapticFeedback.lightImpact();
              onDecrement();
            },
          ),

          Text(
            "₹$stake",
            style: TextStyle(
              color: glow ? Colors.white : Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),

          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () {
              HapticFeedback.mediumImpact();
              onIncrement();
            },
          ),

          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
