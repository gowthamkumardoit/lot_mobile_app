import 'package:flutter/material.dart';
import '../../services/ticket_read_service.dart';
import '../../modals/ticket.dart';
import '../../widgets/lottery_ticket_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/draw_run_service.dart';
import '../../modals/draw_run.dart';

class TicketsPage extends StatelessWidget {
  const TicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          "Please login to view your tickets",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B0F2A), Color(0xFF1B0F4A), Color(0xFF2E1A7A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 14),

              // 🎟️ TITLE
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.confirmation_num, color: Colors.cyanAccent),
                  SizedBox(width: 8),
                  Text(
                    "My Tickets",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                      shadows: [Shadow(color: Colors.cyan, blurRadius: 20)],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 📜 LIST
              Expanded(
                child: StreamBuilder<List<DrawRun>>(
                  stream: DrawService().getTodayDraws(), // or getAllDrawRuns()
                  builder: (context, drawSnap) {
                    if (!drawSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // ✅ PLACE IT HERE
                    final List<DrawRun> draws = drawSnap.data!;

                    // ✅ Build lookup map
                    final Map<String, String> drawNameByRunId = {
                      for (final d in draws)
                        d.id: d.title, // title = drawName ?? drawId
                    };

                    return StreamBuilder<List<Ticket>>(
                      stream: TicketReadService().getActiveTickets(user.uid),
                      builder: (context, ticketSnap) {
                        if (ticketSnap.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (ticketSnap.hasError) {
                          return Center(
                            child: Text(
                              ticketSnap.error.toString(),
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        final tickets = ticketSnap.data ?? [];

                        if (tickets.isEmpty) {
                          return _emptyTickets();
                        }

                        return RefreshIndicator(
                          color: Colors.cyanAccent,
                          onRefresh: () async {
                            await Future.delayed(
                              const Duration(milliseconds: 500),
                            );
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: tickets.length,
                            itemBuilder: (context, i) {
                              final t = tickets[i];

                              return LotteryTicketCard(
                                type: t.type,
                                number: t.number,
                                amount: t.amount,
                                date:
                                    "${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year}",
                                status: t.status,

                                // ✅ CORRECT
                                drawName:
                                    drawNameByRunId[t.drawRunId] ?? "DRAW",
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyTickets() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.receipt_long, size: 48, color: Colors.cyanAccent),
            SizedBox(height: 12),
            Text(
              "No tickets yet",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              "Your tickets will appear here\nonce you play a draw 🎯",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
