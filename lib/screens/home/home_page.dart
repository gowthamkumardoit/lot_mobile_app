import 'package:flutter/material.dart';
import '../../services/draw_run_service.dart';
import '../../modals/draw_run.dart';
import 'package:mobile_app/screens/home/lucky_draw_card.dart';
import 'package:flutter/services.dart';

Widget todayStatusBanner(List<DrawRun> draws) {
  final openDraws = draws.where((d) => d.isOpen).toList();

  // 🔥 HIDE BANNER IF NO OPEN DRAWS
  if (openDraws.isEmpty) return const SizedBox.shrink();

  // ⏳ pick nearest draw
  openDraws.sort(
    (a, b) => (a.drawDateTime ?? DateTime.now()).compareTo(
      b.drawDateTime ?? DateTime.now(),
    ),
  );

  final nextDraw = openDraws.first;
  final dt = nextDraw.drawDateTime;

  final remaining = dt == null ? null : dt.difference(DateTime.now());

  return Container(
    margin: const EdgeInsets.fromLTRB(16, 6, 16, 14),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        colors: [
          Colors.cyanAccent.withOpacity(0.25),
          Colors.blueAccent.withOpacity(0.15),
        ],
      ),
      border: Border.all(color: Colors.cyanAccent.withOpacity(0.6)),
    ),
    child: Row(
      children: [
        const PulseDot(),
        const SizedBox(width: 8),
        Text(
          "${openDraws.length} Live draw${openDraws.length > 1 ? 's' : ''}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          remaining == null ? "Live now 🎯" : formatDuration(remaining),
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    ),
  );
}

String formatDuration(Duration d) {
  if (d.isNegative) return "Closing now";

  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);

  if (h > 0) {
    return "${h}h ${m}m left";
  } else if (m > 0) {
    return "${m}m ${s}s left";
  } else {
    return "${s}s left";
  }
}

class PulseDot extends StatefulWidget {
  const PulseDot({super.key});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: const Icon(Icons.circle, color: Colors.greenAccent, size: 12),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // IMPORTANT
        statusBarIconBrightness: Brightness.light, // Android icons
        statusBarBrightness: Brightness.dark, // iOS icons
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF070B22), Color(0xFF140C3D), Color(0xFF1F0F55)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                /// 📜 DRAW CONTENT
                Expanded(
                  child: StreamBuilder<List<DrawRun>>(
                    stream: DrawService().getTodayDraws(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.cyanAccent,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            snapshot.error.toString(),
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return noDrawsAvailable();
                      }

                      final draws = snapshot.data!;
                      final openDraws = draws.where((d) => d.isOpen).toList();

                      String timeLeft = "Live now 🎯";
                      if (openDraws.isNotEmpty &&
                          openDraws.first.drawDateTime != null) {
                        final remaining = openDraws.first.drawDateTime!
                            .difference(DateTime.now());
                        timeLeft = formatDuration(remaining);
                      }

                      return Column(
                        children: [
                          luckyRajaHeader(
                            liveCount: openDraws.length,
                            timeLeft: timeLeft,
                          ),

                          Expanded(
                            child: RefreshIndicator(
                              color: Colors.cyanAccent,
                              onRefresh: () async {
                                await Future.delayed(
                                  const Duration(milliseconds: 400),
                                );
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  6,
                                  16,
                                  120,
                                ),
                                itemCount: draws.length,
                                itemBuilder: (ctx, i) {
                                  return LuckyDrawCard(draw: draws[i]);
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget noDrawsAvailable() {
  return Center(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.hourglass_empty_rounded,
            size: 48,
            color: Colors.cyanAccent,
          ),
          SizedBox(height: 12),
          Text(
            "No draws available right now",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6),
          Text(
            "New draws will appear here soon.\nCheck back in a while 🎯",
            style: TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

Widget luckyRajaHeader({required int liveCount, required String timeLeft}) {
  return Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(
        colors: [
          Color(0xFF1A1F6B), // royal blue
          Color(0xFF3A1C8C), // purple
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.35),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 👑 APP NAME
        Row(
          children: [
            Icon(
              Icons.emoji_events, // 👑 crown replacement
              color: Color(0xFFFFD700),
              size: 26,
            ),
            const SizedBox(width: 8),
            const Text(
              "Lucky Raja",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        /// ✨ TAGLINE
        const Text(
          "Try your luck in today’s live draws",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),

        const SizedBox(height: 14),

        /// 🔴 LIVE STATUS BAR
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                Colors.cyanAccent.withOpacity(0.25),
                Colors.blueAccent.withOpacity(0.15),
              ],
            ),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.6)),
          ),
          child: Row(
            children: [
              const PulseDot(),
              const SizedBox(width: 8),
              Text(
                "$liveCount Live draw${liveCount > 1 ? 's' : ''}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(timeLeft, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ],
    ),
  );
}
