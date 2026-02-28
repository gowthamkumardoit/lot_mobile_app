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
    final highlight = stake > 100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(
          color: highlight
              ? const Color(0xFFD4A017) // gold highlight
              : const Color(0xFFFFE2D2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          /// 🎯 NUMBER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF2A2A2A),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),

          const Spacer(),

          /// ➖ DECREMENT
          _counterButton(
            icon: Icons.remove,
            onTap: () {
              HapticFeedback.lightImpact();
              onDecrement();
            },
          ),

          const SizedBox(width: 10),

          /// 💰 STAKE
          Text(
            "₹$stake",
            style: TextStyle(
              color: highlight
                  ? const Color(0xFFD4A017) // gold if high
                  : const Color(0xFFFF6A00),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),

          const SizedBox(width: 10),

          /// ➕ INCREMENT
          _counterButton(
            icon: Icons.add,
            onTap: () {
              HapticFeedback.mediumImpact();
              onIncrement();
            },
          ),

          const SizedBox(width: 8),

          /// 🗑 DELETE
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: Color(0xFFE74C3C),
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _counterButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFFF6A00).withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: const Color(0xFFFF6A00)),
      ),
    );
  }
}
