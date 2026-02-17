import 'package:flutter/material.dart';

class LotteryTicketCard extends StatelessWidget {
  final String type; // 2D / 3D / 4D
  final String number;
  final int amount;
  final String date;
  final String status;
  final String drawName;

  const LotteryTicketCard({
    super.key,
    required this.type,
    required this.number,
    required this.amount,
    required this.date,
    required this.status,
    required this.drawName,
  });

  bool get is2D => type == "2D";
  bool get is4D => type == "4D";

  @override
  Widget build(BuildContext context) {
    final Color accent = is4D
        ? const Color(0xFFFFD54F) // GOLD
        : is2D
        ? Colors.cyanAccent
        : Colors.purpleAccent;

    final Gradient bgGradient = is4D
        ? const LinearGradient(
            colors: [
              Color(0xFF3A2E00), // dark gold
              Color(0xFFFFC107), // gold
              Color(0xFFFFA000), // deep gold
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : is2D
        ? const LinearGradient(
            colors: [
              Color(0xFF003B44), // deep cyan
              Color(0xFF00BCD4), // cyan glow
              Color(0xFF00838F), // rich cyan
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [
              Color(0xFF2A0F3D), // deep purple
              Color(0xFF9C27B0), // neon purple
              Color(0xFF6A1B9A), // royal purple
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: bgGradient,
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(is4D ? 0.6 : 0.25),
            blurRadius: is4D ? 28 : 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // 🔢 NUMBER CHIP
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.black.withOpacity(0.35),
              border: Border.all(color: accent, width: is4D ? 1.4 : 1),
            ),
            child: Text(
              number,
              style: TextStyle(
                color: accent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // 📄 DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$type TICKET",
                  style: TextStyle(
                    color: is4D ? Colors.brown.shade900 : Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Amount ₹$amount",
                  style: TextStyle(
                    color: is4D ? Colors.brown.shade800 : Colors.white70,
                    fontSize: 13,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    color: is4D ? Colors.brown.shade700 : Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // 📊 STATUS
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              status == "PENDING"
                  ? _drawNameChip(drawName, accent)
                  : _statusChip(status, accent),

              const SizedBox(height: 8),
              _barcode(is4D),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status, Color accent) {
    Color c;
    switch (status) {
      case "WON":
        c = Colors.greenAccent;
        break;
      case "LOST":
        c = Colors.redAccent;
        break;
      default:
        c = Colors.orangeAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c),
      ),
      child: Text(
        status,
        style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _drawNameChip(String drawName, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent),
      ),
      child: Text(
        drawName.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _barcode(bool is4D) {
    return Column(
      children: List.generate(
        5,
        (i) => Container(
          width: i.isEven ? 18 : 26,
          height: 3,
          margin: const EdgeInsets.symmetric(vertical: 1),
          color: is4D ? Colors.brown.shade900 : Colors.white70,
        ),
      ),
    );
  }
}
