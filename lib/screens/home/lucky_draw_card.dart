import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mobile_app/modals/draw_run.dart';
import 'package:mobile_app/screens/tickets/ticket_select_page.dart';
import 'package:mobile_app/widgets/night_sky.dart';

class LuckyDrawCard extends StatefulWidget {
  final DrawRun draw;
  final bool isLoading;

  const LuckyDrawCard({super.key, required this.draw, this.isLoading = false});

  @override
  State<LuckyDrawCard> createState() => _LuckyDrawCardState();
}

class _LuckyDrawCardState extends State<LuckyDrawCard>
    with TickerProviderStateMixin {
  Timer? _timer;
  String _countdownText = "";

  late AnimationController _resultController;
  late Animation<double> _resultScale;
  late AnimationController _glowController;
  late Animation<double> _glowAnim;
  late AnimationController _countdownPulse;
  late Animation<double> _countdownScale;

  @override
  void initState() {
    super.initState();

    _startCountdown();

    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _resultScale = CurvedAnimation(
      parent: _resultController,
      curve: Curves.elasticOut,
    );

    if (widget.draw.isCompleted) {
      _resultController.forward();
    }

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.25, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _countdownPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _countdownScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _countdownPulse, curve: Curves.easeInOut),
    );

    // stop glow if not open
    if (!widget.draw.isOpen) {
      _glowController.stop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resultController.dispose();
    _glowController.dispose();
    _countdownPulse.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.draw.isCompleted || !widget.draw.isOpen) {
        if (_timer?.isActive ?? false) {
          _timer!.cancel();
        }

        _glowController.stop();
        _countdownPulse.stop();
        return;
      }

      final remaining = widget.draw.drawDateTime?.difference(DateTime.now());

      setState(() {
        _countdownText = _calculateCountdown(widget.draw.drawDateTime);
      });

      if (remaining != null && remaining.inSeconds <= 60) {
        if (!_countdownPulse.isAnimating) {
          _countdownPulse.repeat(reverse: true);
        }
      } else {
        _countdownPulse.stop();
        _countdownPulse.reset();
      }
    });
  }

  String _calculateCountdown(DateTime? drawDateTime) {
    if (drawDateTime == null) return "--:--:--";

    final now = DateTime.now();
    final diff = drawDateTime.difference(now);

    if (diff.isNegative) {
      return "00:00:00";
    }

    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');

    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return _buildSkeleton();

    final draw = widget.draw;
    final isCompleted = draw.isCompleted;
    final isOpen = draw.isOpen && !isCompleted;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Stack(
        children: [
          const Positioned.fill(child: NightSky()),

          /// SOFT OUTER GLOW BEHIND CARD
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(
                      255,
                      249,
                      249,
                      250,
                    ).withOpacity(0.35),
                    blurRadius: 80,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),

          /// MAIN CARD
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                colors: [Color(0xFF0E1432), Color(0xFF131C46)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFFFFD76A).withOpacity(0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFFD76A), size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        draw.title.isNotEmpty ? draw.title : "Night Special",
                        style: const TextStyle(
                          color: Color(0xFFFFE6A3),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    /// GOLD OPEN BADGE
                    if (isOpen)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFE29F), Color(0xFFFFC371)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFFFC371).withOpacity(0.6),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Text(
                          "OPEN",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 6),
                Divider(color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 10),

                /// 🎲 TIER CARDS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _luxuryTier("2D", "x${draw.multiplier2D}", Icons.casino),
                    _luxuryTier(
                      "3D",
                      "x${draw.multiplier3D}",
                      Icons.confirmation_number,
                    ),
                    _luxuryTier("4D", "x${draw.multiplier4D}", Icons.diamond),
                  ],
                ),

                const SizedBox(height: 20),

                /// 🔥 PREMIUM BUY BUTTON
                if (!isCompleted)
                  Container(
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8A3D), Color(0xFFFF5F6D)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6A00).withOpacity(0.6),
                          blurRadius: 25,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: isOpen
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TicketSelectPage(draw: draw),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(
                        Icons.local_activity,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Buy Tickets",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 18),

                /// ⏳ COUNTDOWN (LIVE + PULSE LAST 60s)
                Center(
                  child: ScaleTransition(
                    scale: _countdownScale,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.hourglass_bottom_rounded,
                          size: 16,
                          color: _countdownPulse.isAnimating
                              ? Colors.orangeAccent
                              : Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Closing in $_countdownText",
                          style: TextStyle(
                            color: _countdownPulse.isAnimating
                                ? Colors.orangeAccent
                                : Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (!isOpen && !isCompleted)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: Colors.black.withOpacity(0.35),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.lock_rounded,
                          color: Color(0xFFFFD76A),
                          size: 40,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "LOCKED",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _luxuryTier(String title, String value, IconData icon) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD76A).withOpacity(0.4),
            blurRadius: 25,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFFFD76A), size: 26),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _warmTierTile(IconData icon, String title, String value, Color color) {
    return Container(
      width: 80,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFFFF1E6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2A2A2A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultBanner() {
    return ScaleTransition(
      scale: _resultScale,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.greenAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.greenAccent),
        ),
        child: const Center(
          child: Text(
            "🎉 RESULT DECLARED",
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// SKELETON LOADER
  Widget _buildSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white12,
      ),
    );
  }
}
