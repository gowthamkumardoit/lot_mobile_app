import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/modals/digit_draw_slot.dart';
import 'package:mobile_app/pages/ticket_purchase_page.dart';

class DigitSlotCard extends StatefulWidget {
  final DigitDrawSlot slot;

  const DigitSlotCard({super.key, required this.slot});

  @override
  State<DigitSlotCard> createState() => _DigitSlotCardState();
}

class _DigitSlotCardState extends State<DigitSlotCard> {
  late DateTime closeTime;
  late Timer timer;
  bool isClosed = false;

  @override
  void initState() {
    super.initState();

    closeTime = widget.slot.closeAt.toLocal();
    _updateStatus();

    timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateStatus());
  }

  void _updateStatus() {
    final now = DateTime.now();
    final closed = now.isAfter(closeTime);

    if (mounted) {
      setState(() {
        isClosed = closed;
      });
    }
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prizes = widget.slot.prizes;

    final jackpot = NumberFormat("#,##,###").format(prizes['exact'] ?? 0);
    final second = NumberFormat("#,##,###").format(prizes['minusOne'] ?? 0);
    final third = NumberFormat("#,##,###").format(prizes['minusTwo'] ?? 0);
    final ticket = NumberFormat("#,##,###").format(widget.slot.ticketPrice);

    final difference = closeTime.difference(DateTime.now());
    final hours = difference.isNegative ? 0 : difference.inHours;
    final minutes = difference.isNegative ? 0 : difference.inMinutes % 60;
    final seconds = difference.isNegative ? 0 : difference.inSeconds % 60;

    int digits = widget.slot.digits;

    int exactWinners = 1;
    int secondPrizeWinners = 0;
    int thirdPrizeWinners = 0;

    if (digits >= 2) {
      secondPrizeWinners = 9;
    }

    if (digits >= 3) {
      thirdPrizeWinners = 90;
    }
    return GestureDetector(
      onTap: isClosed
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketPurchasePage(slot: widget.slot),
                ),
              );
            },
      child: Stack(
        children: [
          Opacity(
            opacity: isClosed ? 0.55 : 1,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Stack(
                children: [
                  /// 🔥 Thin Gold Border (Rectangular)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFFFC94A),
                        width: 1.2, // thinner border
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16, // reduced vertical padding
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0B1635), Color(0xFF1E2E5A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          /// ✨ Background Lines
                          Positioned.fill(
                            child: CustomPaint(painter: _GoldLinePainter()),
                          ),

                          /// CONTENT
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize:
                                MainAxisSize.min, // 👈 makes it compact
                            children: [
                              /// Header
                              Row(
                                children: [
                                  Text(
                                    "${widget.slot.digits} Digit Lottery",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFFE39B),
                                          Color(0xFFFFC94A),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Text(
                                      "Ticket ₹$ticket",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF5A3E00),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              /// Jackpot
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                      colors: [
                                        Color(0xFFFFF2B0),
                                        Color(0xFFFFC94A),
                                      ],
                                    ).createShader(bounds),
                                child: Text(
                                  "₹$jackpot",
                                  style: const TextStyle(
                                    fontSize: 30, // slightly smaller
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              /// Prize Section
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3DA),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (digits >= 2)
                                      _premiumPrize(
                                        "${digits - 1} Digit Prize",
                                        second,
                                        secondPrizeWinners,
                                      ),
                                    if (digits >= 3)
                                      _premiumPrize(
                                        "${digits - 2} Digit Prize",
                                        third,
                                        thirdPrizeWinners,
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 14),

                              /// Countdown
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFE4E4),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.timer_outlined,
                                      color: Colors.redAccent,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isClosed
                                          ? "Closed"
                                          : "Closing in ${hours.toString().padLeft(2, '0')}:"
                                                "${minutes.toString().padLeft(2, '0')}:"
                                                "${seconds.toString().padLeft(2, '0')} hrs",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (isClosed)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: Colors.white.withOpacity(0.65),
                        ),
                        child: const Center(
                          child: Icon(Icons.lock, size: 36, color: Colors.red),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumPrize(String title, String amount, int winners) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF333333),
            ),
            children: [
              TextSpan(text: "₹$amount "),
              TextSpan(
                text: "× $winners",
                style: const TextStyle(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoldLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD77A).withOpacity(0.15)
      ..strokeWidth = 1;

    final path1 = Path()
      ..moveTo(size.width * 0.1, 0)
      ..lineTo(size.width, size.height * 0.4);

    final path2 = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width * 0.7, size.height);

    final path3 = Path()
      ..moveTo(size.width * 0.4, 0)
      ..lineTo(size.width, size.height * 0.8);

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
