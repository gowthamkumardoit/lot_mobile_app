import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:mobile_app/widgets/ticket_confirmation_sheet.dart';

import '../../modals/draw_run.dart';
import '../../services/ticket_service.dart';

import '../../widgets/entry_header.dart';
import '../../widgets/number_input_row.dart';
import '../../widgets/stake_row.dart';
import 'package:mobile_app/modals/entry_config.dart';

class TwoDEntryPage extends StatefulWidget {
  final DrawRun draw;
  const TwoDEntryPage({super.key, required this.draw});

  @override
  State<TwoDEntryPage> createState() => _TwoDEntryPageState();
}

class _TwoDEntryPageState extends State<TwoDEntryPage>
    with SingleTickerProviderStateMixin {
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
    config = EntryConfig.twoD(widget.draw);

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

    if (text.length != 2 || int.tryParse(text) == null) {
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

        // ✅ ONLY CHANGE IS HERE
        onConfirm: () async {
          if (_isSubmitting) return;
          setState(() => _isSubmitting = true);
          await confirmTicket();
        },
      ),
    );
  }

  Future<void> confirmTicket() async {
    try {
      await TicketService().purchase2DTicket(
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
          content: Text("🎉 Ticket placed successfully"),
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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B0F2A), Color(0xFF1B0F4A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(confettiController: _confetti),
          ),

          SafeArea(
            child: Column(
              children: [
                EntryHeader(
                  title: "2D Entry",
                  onBack: () => Navigator.pop(context),
                ),

                const SizedBox(height: 24),

                NumberInputRow(
                  controller: _numberCtrl,
                  digits: 2,
                  onAdd: addNumber,
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: numbers.isEmpty
                      ? const Center(
                          child: Text(
                            "Add numbers",
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: numbers.entries.map((e) {
                            return StakeRow(
                              number: e.key,
                              stake: e.value,
                              onDecrement: () {
                                if (numbers[e.key]! > 10) {
                                  setState(() {
                                    numbers[e.key] = numbers[e.key]! - 10;
                                  });
                                }
                              },
                              onIncrement: () {
                                setState(() {
                                  numbers[e.key] = numbers[e.key]! + 10;
                                });
                              },
                              onDelete: () {
                                setState(() {
                                  numbers.remove(e.key);
                                });
                              },
                            );
                          }).toList(),
                        ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: numbers.isEmpty || _isSubmitting
                        ? null
                        : showConfirmSheet,
                    child: Text("CONTINUE • ₹$totalStake"),
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
