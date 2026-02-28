import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';

import '../../modals/draw_run.dart';
import '../../services/ticket_service.dart';
import 'package:mobile_app/modals/entry_config.dart';

import '../../widgets/number_input_row.dart';
import '../../widgets/stake_row.dart';
import 'package:mobile_app/widgets/ticket_confirmation_sheet.dart';

class FourDEntryPage extends StatefulWidget {
  final DrawRun draw;
  const FourDEntryPage({super.key, required this.draw});

  @override
  State<FourDEntryPage> createState() => _FourDEntryPageState();
}

class _FourDEntryPageState extends State<FourDEntryPage> {
  final TextEditingController _numberCtrl = TextEditingController();
  final Map<String, int> numbers = {};

  late ConfettiController _confetti;
  bool _isSubmitting = false;
  StreamSubscription? _drawSub;
  late EntryConfig config;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    config = EntryConfig.fourD(widget.draw);

    _drawSub = widget.draw.stream().listen((d) {
      if (!mounted) return;
      if (d.isLocked || d.isCompleted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    });
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _confetti.dispose();
    _drawSub?.cancel();
    super.dispose();
  }

  void addNumber() {
    final text = _numberCtrl.text;

    if (text.length != 4 || int.tryParse(text) == null) {
      HapticFeedback.mediumImpact();
      return;
    }

    setState(() {
      numbers.putIfAbsent(text, () => 10);
      _numberCtrl.clear();
    });
  }

  int get totalStake => numbers.values.fold(0, (sum, v) => sum + v);

  void showConfirmSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TicketConfirmationSheet(
        draw: widget.draw,
        config: config,
        numbers: numbers,
        total: totalStake,
        onCancel: () => Navigator.pop(context),
        onConfirm: () async {
          if (_isSubmitting) return;
          setState(() => _isSubmitting = true);
          await confirmTicket();
        },
      ),
    );
  }

  Future<void> confirmTicket() async {
    setState(() => _isSubmitting = true);

    try {
      await TicketService().purchase4DTicket(
        drawId: widget.draw.id,
        numbers: numbers,
      );

      _confetti.play();

      setState(() {
        numbers.clear();
        _numberCtrl.clear();
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🎉 4D Ticket placed successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFFFF8F2),
    body: Stack(
      children: [

        /// 🎉 Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(confettiController: _confetti),
        ),

        SafeArea(
          child: Column(
            children: [

              /// 🔙 HEADER
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Color(0xFF2A2A2A),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "4D Entry",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2A2A2A),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              /// 🔢 NUMBER INPUT SECTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFFE2D2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: NumberInputRow(
                    controller: _numberCtrl,
                    digits: 4,
                    onAdd: addNumber,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// 📋 NUMBERS LIST
              Expanded(
                child: numbers.isEmpty
                    ? const Center(
                        child: Text(
                          "Add numbers to continue",
                          style: TextStyle(
                            color: Color(0xFF777777),
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: numbers.entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: StakeRow(
                              number: e.key,
                              stake: e.value,
                              onDecrement: () {
                                if (numbers[e.key]! > 10) {
                                  setState(() {
                                    numbers[e.key] =
                                        numbers[e.key]! - 10;
                                  });
                                }
                              },
                              onIncrement: () {
                                setState(() {
                                  numbers[e.key] =
                                      numbers[e.key]! + 10;
                                });
                              },
                              onDelete: () {
                                setState(() {
                                  numbers.remove(e.key);
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
              ),

              /// 🔘 STICKY TOTAL + BUTTON
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8F2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [

                    /// TOTAL ROW
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Stake",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF777777),
                          ),
                        ),
                        Text(
                          "₹$totalStake",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF6A00),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            numbers.isEmpty || _isSubmitting
                                ? null
                                : showConfirmSheet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFFF6A00),
                          disabledBackgroundColor:
                              Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          padding:
                              const EdgeInsets.symmetric(
                                  vertical: 14),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Continue",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.w600,
                                  color: Colors.white,
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
      ],
    ),
  );
}
}
