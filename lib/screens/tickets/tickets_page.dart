import 'package:flutter/material.dart';
import '../../services/ticket_read_service.dart';
import '../../services/kuber_gold_ticket_read_service.dart';
import '../../modals/ticket.dart';
import '../../widgets/lottery_ticket_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/draw_run_service.dart';
import '../../modals/draw_run.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  Key _refreshKey = UniqueKey();

  Future<void> _handleRefresh() async {
    setState(() {
      _refreshKey = UniqueKey(); // forces rebuild
    });

    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          "Please login to view your tickets",
          style: TextStyle(color: Color(0xFF2A2A2A), fontSize: 14),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8F2),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 14),

              /// 🎟 TITLE
              const Text(
                "My Tickets",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2A2A2A),
                ),
              ),

              const SizedBox(height: 16),

              /// 🔥 TABS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TabBar(
                  indicatorColor: const Color(0xFFFF6A00),
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: const Color(0xFF2A2A2A),
                  unselectedLabelColor: const Color(0xFF777777),
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: "Kuber Gold"),
                    Tab(text: "Kuber X"),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              /// 📜 TAB CONTENT
              Expanded(
                child: TabBarView(
                  children: [
                    /// 🥇 GOLD TAB (Empty for now)
                    _goldTab(user),

                    /// ⚡ KUBER X TAB (Your Tickets)
                    _kuberXTab(user),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _goldTab(User user) {
    return RefreshIndicator(
      color: const Color(0xFFD4A017),
      onRefresh: _handleRefresh,
      child: StreamBuilder<List<Ticket>>(
        key: _refreshKey,
        stream: KuberGoldTicketReadService().getUserGoldTickets(user.uid),
        builder: (context, ticketSnap) {
          if (ticketSnap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4A017)),
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
            return Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFFFE2D2)),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      size: 42,
                      color: Color(0xFFD4A017),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "No Kuber Gold tickets yet",
                      style: TextStyle(
                        color: Color(0xFF2A2A2A),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
            itemCount: tickets.length,
            itemBuilder: (context, i) {
              final t = tickets[i];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: LotteryTicketCard(
                  type: t.type,
                  number: t.number,
                  amount: t.amount,
                  winAmount: t.winAmount,
                  winningNumber: t.winningNumber,
                  date:
                      "${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year}",
                  status: t.status,
                  drawName: "KUBER GOLD",
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _kuberXTab(User user) {
    return StreamBuilder<List<DrawRun>>(
      stream: DrawService().getTodayDraws(),
      builder: (context, drawSnap) {
        if (!drawSnap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6A00)),
          );
        }

        final draws = drawSnap.data!;
        final Map<String, String> drawNameByRunId = {
          for (final d in draws) d.id: d.title,
        };

        return StreamBuilder<List<Ticket>>(
          stream: TicketReadService().getActiveTickets(user.uid),
          builder: (context, ticketSnap) {
            if (ticketSnap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF6A00)),
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
              color: const Color(0xFFFF6A00),
              onRefresh: _handleRefresh,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                key: _refreshKey,
                padding: const EdgeInsets.only(
                  bottom: 100,
                  left: 16,
                  right: 16,
                ),
                itemCount: tickets.length,
                itemBuilder: (context, i) {
                  final t = tickets[i];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: LotteryTicketCard(
                      type: t.type,
                      number: t.number,
                      amount: t.amount,
                      winAmount: t.winAmount,
                      winningNumber: t.winningNumber,
                      date:
                          "${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year}",
                      status: t.status,
                      drawName: drawNameByRunId[t.drawRunId] ?? "DRAW",
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyTickets() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFFFE2D2)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              size: 42,
              color: Color(0xFFD4A017),
            ),
            SizedBox(height: 12),
            Text(
              "No Kuber X tickets yet",
              style: TextStyle(
                color: Color(0xFF2A2A2A),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
