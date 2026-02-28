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
      height: height * 0.65,
      child: Stack(
        children: [
          /// 🎉 CONFETTI (warm colors)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              blastDirection: -1,
              emissionFrequency: 0.15,
              numberOfParticles: 80,
              gravity: 0.25,
              minimumSize: const Size(6, 6),
              maximumSize: const Size(12, 12),
              colors: const [
                Color(0xFFFF6A00),
                Color(0xFFD4A017),
                Color(0xFFFFC107),
                Color(0xFFFF8C42),
                Colors.white,
              ],
              shouldLoop: false,
            ),
          ),

          /// MAIN CONTENT
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8F2),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                /// DRAG HANDLE
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                /// HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF2A2A2A)),
                        onPressed: _isSubmitting ? null : widget.onCancel,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Confirm Ticket",
                        style: TextStyle(
                          color: Color(0xFF2A2A2A),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                /// DRAW TITLE
                Text(
                  widget.draw.title,
                  style: const TextStyle(
                    color: Color(0xFF2A2A2A),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "${widget.config.type.name.toUpperCase()} • Win x${widget.config.multiplier}",
                  style: const TextStyle(color: Color(0xFF777777)),
                ),

                const SizedBox(height: 16),

                /// NUMBER LIST
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: widget.numbers.entries.map((e) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFFE2D2)),
                        ),
                        child: Row(
                          children: [
                            Text(
                              e.key,
                              style: const TextStyle(
                                color: Color(0xFF2A2A2A),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "₹${e.value}",
                              style: const TextStyle(
                                color: Color(0xFFFF6A00),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const Divider(color: Color(0xFFFFE2D2), thickness: 1),

                /// TOTAL
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        "Total",
                        style: TextStyle(
                          color: Color(0xFF777777),
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "₹${widget.total}",
                        style: const TextStyle(
                          color: Color(0xFFFF6A00),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                /// ACTION BUTTONS
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    24 + MediaQuery.of(context).viewPadding.bottom,
                  ),
                  child: Row(
                    children: [
                      /// CANCEL
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : widget.onCancel,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFF6A00)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Color(0xFFFF6A00)),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      /// CONFIRM
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleConfirm,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            backgroundColor: const Color(0xFFFF6A00),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Confirm",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// LOADING OVERLAY
          if (_isSubmitting)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: const Center(
                child: SizedBox(
                  height: 42,
                  width: 42,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF6A00),
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
