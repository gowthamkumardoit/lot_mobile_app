import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../modals/draw_run.dart';
import 'package:mobile_app/modals/entry_config.dart';

class TicketConfirmationSheet extends StatefulWidget {
  final DrawRun draw;
  final EntryConfig config;
  final Map<String, int> numbers;
  final int total;
  final VoidCallback onCancel;
  final Future<void> Function() onConfirm;

  const TicketConfirmationSheet({
    super.key,
    required this.draw,
    required this.config,
    required this.numbers,
    required this.total,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<TicketConfirmationSheet> createState() =>
      _TicketConfirmationSheetState();
}

class _TicketConfirmationSheetState extends State<TicketConfirmationSheet> {
  bool _isSubmitting = false;
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await widget.onConfirm();

      _confetti.play();
      await Future.delayed(const Duration(milliseconds: 900));

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      showDialog(
        context: context,
        useRootNavigator: true,
        builder: (ctx) => AlertDialog(
          title: const Text("Transaction Failed"),
          content: Text(e.toString().replaceAll('Exception: ', '')),
          actions: [
            TextButton(
              onPressed: () {
                // 1️⃣ Close dialog
                Navigator.of(ctx).pop();

                // 2️⃣ Close bottom sheet
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return SizedBox(
      height: height * 0.65, // ⬅️ SAME SIZE AS BEFORE
      child: Stack(
        children: [
          // 🎉 CONFETTI
          Align(
            alignment: Alignment.topCenter,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,

                // 🔑 CRITICAL FIXES
                blastDirectionality:
                    BlastDirectionality.explosive, // symmetric spread
                blastDirection: -1, // MUST be -1 for explosive

                emissionFrequency: 0.15,
                numberOfParticles: 100,
                gravity: 0.2,

                // Size
                minimumSize: const Size(6, 6),
                maximumSize: const Size(12, 12),

                // Colors
                colors: const [
                  Colors.cyanAccent,
                  Colors.pinkAccent,
                  Colors.amber,
                  Colors.greenAccent,
                  Colors.purpleAccent,
                  Colors.white,
                ],

                shouldLoop: false,
              ),
            ),
          ),

          // MAIN CONTENT
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0D1028),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // DRAG HANDLE
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                // HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _isSubmitting ? null : widget.onCancel,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Confirm Ticket",
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  widget.draw.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  "${widget.config.type.name.toUpperCase()} • Win x${widget.config.multiplier}",
                  style: const TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 16),

                // LIST
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: widget.numbers.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              e.key,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "₹${e.value}",
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const Divider(color: Colors.white24),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        "Total",
                        style: TextStyle(color: Colors.white70),
                      ),
                      const Spacer(),
                      Text(
                        "₹${widget.total}",
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    24 + MediaQuery.of(context).viewPadding.bottom,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : widget.onCancel,
                          child: const Text("CANCEL"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleConfirm,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            backgroundColor: Colors.white,
                          ),
                          child: const Text(
                            "CONFIRM",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 🔥 LOADING OVERLAY (THIS IS THE KEY FIX)
          if (_isSubmitting)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: const Center(
                child: SizedBox(
                  height: 48,
                  width: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.cyanAccent,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
