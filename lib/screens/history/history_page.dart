import 'package:flutter/material.dart';
import '../../modals/ticket.dart';
import '../../services/ticket_read_service.dart';
import '../../services/draw_result_service.dart';
import '../../modals/draw_with_result.dart';
import '../../modals/draw_result.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          "Please login to view tickets",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF090D20), Color(0xFF130B2E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 14),

              // 🕓 TITLE
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.history, color: Colors.white70),
                  SizedBox(width: 8),
                  Text(
                    "History",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<Ticket>>(
                  stream: TicketReadService().getUserTickets(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          snapshot.error.toString(),
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final all = snapshot.data ?? [];

                    // ⛔ only settled tickets
                    final historyTickets = all
                        .where((t) => t.status != 'PENDING')
                        .toList();

                    if (historyTickets.isEmpty) {
                      return _emptyHistory();
                    }

                    // 🔁 group by draw
                    final grouped = <String, List<Ticket>>{};
                    for (final t in historyTickets) {
                      grouped.putIfAbsent(t.drawRunId, () => []).add(t);
                    }

                    return ListView(
                      padding: const EdgeInsets.only(bottom: 100),
                      children: grouped.entries.map((entry) {
                        return _drawAccordion(
                          drawRunId: entry.key,
                          tickets: entry.value,
                        );
                      }).toList(),
                    );
                  },
                ),
              ),

              // 📜 HISTORY LIST
            ],
          ),
        ),
      ),
    );
  }

  // 🎯 DRAW SECTION

  // 🎟️ HISTORY TICKET CARD

  // 📭 EMPTY STATE
  Widget _emptyHistory() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.event_busy, size: 48, color: Colors.white54),
            SizedBox(height: 12),
            Text(
              "No history yet",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              "Your completed tickets will\nappear here after results 🎯",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _drawAccordion({
  required String drawRunId,
  required List<Ticket> tickets,
}) {
  final date = tickets.first.createdAt;

  return FutureBuilder<DrawWithResult?>(
    future: DrawResultService().getDrawWithResults(drawRunId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        );
      }

      if (!snapshot.hasData || snapshot.data == null) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "⚠️ Draw data not available",
            style: TextStyle(color: Colors.redAccent),
          ),
        );
      }

      final draw = snapshot.data!;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white24),
        ),
        child: ExpansionTile(
          iconColor: Colors.cyanAccent,
          collapsedIconColor: Colors.white70,

          // ✅ DRAW NAME SHOWN HERE (REQUIREMENT MET)
          title: Text(
            draw.drawName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          subtitle: Text(
            "${date.day}/${date.month}/${date.year} • ${tickets.length} ticket(s)",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),

          children: [
            // ✅ PASS RESULTS DIRECTLY
            _winningNumbersSection(draw.results),

            const SizedBox(height: 8),

            ...tickets.map((t) => _historyTicketRow(t, draw.results)),
          ],
        ),
      );
    },
  );
}

Widget _winningNumbersSection(List<DrawResult> results) {
  if (results.isEmpty) return const SizedBox.shrink();

  return Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: Colors.black.withOpacity(0.3),
      border: Border.all(color: Colors.cyanAccent.withOpacity(0.6)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Winning Numbers",
          style: TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: results.map((r) {
            return WinChip("${r.type} • ${r.number}");
          }).toList(),
        ),
      ],
    ),
  );
}

class WinChip extends StatefulWidget {
  final String text;
  const WinChip(this.text, {super.key});

  @override
  State<WinChip> createState() => _WinChipState();
}

class _WinChipState extends State<WinChip> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(
        begin: 1.0,
        end: 1.08,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.cyanAccent.withOpacity(0.15),
          border: Border.all(color: Colors.cyanAccent),
        ),
        child: Text(
          widget.text,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

Widget _historyTicketRow(Ticket t, List<DrawResult> results) {
  final winning = t.status == "WON"; // ✅ SOURCE OF TRUTH

  return AnimatedContainer(
    duration: const Duration(milliseconds: 400),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: winning
          ? Colors.greenAccent.withOpacity(0.18)
          : Colors.white.withOpacity(0.04),
      border: Border.all(
        color: winning ? Colors.greenAccent : Colors.white24,
        width: winning ? 1.5 : 1,
      ),
      boxShadow: winning
          ? [
              BoxShadow(
                color: Colors.greenAccent.withOpacity(0.8),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ]
          : [],
    ),
    child: Row(
      children: [
        Text(
          t.number,
          style: TextStyle(
            color: winning ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        Text(
          t.type,
          style: TextStyle(color: winning ? Colors.black87 : Colors.white70),
        ),
        const SizedBox(width: 12),
        Text(
          winning ? "WON +₹${t.winAmount}" : "LOST",
          style: TextStyle(
            color: winning ? Colors.black : Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
