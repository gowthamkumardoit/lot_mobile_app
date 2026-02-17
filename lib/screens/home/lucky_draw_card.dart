import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mobile_app/modals/draw_run.dart';
import 'package:mobile_app/screens/tickets/ticket_select_page.dart';

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
    final isLocked = draw.isLocked;
    final isOpen = draw.isOpen && !isCompleted;

    final statusText = draw.isCompleted
        ? "DRAWN"
        : isLocked
        ? "LOCKED"
        : "OPEN";

    final statusColor = draw.isCompleted
        ? Colors.greenAccent
        : isLocked
        ? Colors.orangeAccent
        : Colors.cyanAccent;

    return Stack(
      children: [
        AnimatedBuilder(
          animation: _glowAnim,
          builder: (context, _) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F3BFF), Color(0xFF25196F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isOpen
                        ? Colors.cyanAccent.withOpacity(_glowAnim.value)
                        : statusColor.withOpacity(0.35),
                    blurRadius: isOpen ? 30 : 20,
                    spreadRadius: isOpen ? 2 : 0,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🟣 HEADER
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          draw.title.isNotEmpty ? draw.title : "Lucky Draw",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      _statusBadge(statusText, statusColor),
                    ],
                  ),

                  const SizedBox(height: 10),
                  _divider(),

                  const SizedBox(height: 14),

                  /// 🎰 PRIZE TIERS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _slotBoxNeon(
                        icon: "🎲",
                        title: "2D",
                        value: "x${draw.multiplier2D}",
                        color: Colors.cyanAccent,
                      ),
                      _slotBoxNeon(
                        icon: "🎰",
                        title: "3D",
                        value: "x${draw.multiplier3D}",
                        color: Colors.purpleAccent,
                      ),
                      _slotBoxNeon(
                        icon: "💎",
                        title: "4D",
                        value: "x${draw.multiplier4D}",
                        color: Colors.amberAccent,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  /// 🎉 RESULT / CTA
                  if (draw.isCompleted)
                    _resultBanner()
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isOpen
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        TicketSelectPage(draw: draw),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 6,
                        ),
                        child: const Text(
                          "🎟 Buy Tickets",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  /// ⏳ FOOTER
                  Center(
                    child: ScaleTransition(
                      scale: _countdownScale,
                      child: Text(
                        draw.isCompleted
                            ? "🏁 Draw completed"
                            : isOpen
                            ? "⏳ Closing in $_countdownText"
                            : "🕒 Draw time: ${draw.drawTime}",
                        style: TextStyle(
                          color: isOpen && _countdownPulse.isAnimating
                              ? Colors.redAccent
                              : Colors.cyanAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        /// 🔒 LOCK OVERLAY
        if (isLocked && !draw.isCompleted)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  color: Colors.black.withOpacity(0.35),
                  alignment: Alignment.center,
                  child: const Text(
                    "🔒 LOCKED",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
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

  Widget _divider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.white24, Colors.transparent],
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

  Widget _slotBox(String icon, String title, String value) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _slotBoxNeon({
    required String icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.35), color.withOpacity(0.15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
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
