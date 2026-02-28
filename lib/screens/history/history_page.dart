import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/lottery_ticket_card.dart';
import '../../modals/ticket.dart';
import '../../services/ticket_read_service.dart';
import '../../services/draw_result_service.dart';
import '../../modals/draw_with_result.dart';
import '../../modals/draw_result.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Key _refreshKey = UniqueKey();

  Future<void> _handleRefresh() async {
    setState(() {
      _refreshKey = UniqueKey(); // forces StreamBuilder rebuild
    });

    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("Please login to view tickets"));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            const Text(
              "History",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1E1E),
              ),
            ),

            const SizedBox(height: 16),

            /// 🔥 TABS
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFF6A3D),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFFF6A3D),
              tabs: const [
                Tab(text: "KUBER GOLD"),
                Tab(text: "KUBER X"),
              ],
            ),

            const SizedBox(height: 8),

            /// 🔥 TAB CONTENT
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _kuberGoldHistory(user.uid), // For now empty
                  _kuberXHistory(user.uid), // Existing history
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kuberGoldHistory(String uid) {
    return RefreshIndicator(
      color: const Color(0xFFD4A017),
      onRefresh: _handleRefresh,
      child: StreamBuilder<List<Ticket>>(
        key: _refreshKey,
        stream: TicketReadService().getUserKuberGoldTickets(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                height: 32,
                width: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Something went wrong",
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final goldTickets = snapshot.data ?? [];

          if (goldTickets.isEmpty) {
            return _emptyGoldTab();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: goldTickets.length,
            itemBuilder: (context, index) {
              final t = goldTickets[index];

              final formattedDate =
                  "${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year}";

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: LotteryTicketCard(
                  type: t.type,
                  number: t.number,
                  amount: t.amount,
                  date: formattedDate,
                  status: t.status,
                  drawName: "Kuber Gold",
                  winningNumber: t.winningNumber,
                  winAmount: t.winAmount,
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 🟡 KUBER GOLD TAB (Currently Empty)
  Widget _emptyGoldTab() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
                ),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "No Kuber Gold History Yet",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your Kuber Gold completed tickets\nwill appear here once declared.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔵 KUBER X TAB (Current existing history logic)
  Widget _kuberXHistory(String uid) {
    return RefreshIndicator(
      color: const Color(0xFFFF6A3D),
      onRefresh: _handleRefresh,
      child: StreamBuilder<List<Ticket>>(
        key: _refreshKey,
        stream: TicketReadService().getUserTickets(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                height: 32,
                width: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final allTickets = snapshot.data ?? [];

          // 🔥 Only history (exclude pending)
          final historyTickets = allTickets
              .where((t) => t.status != 'PENDING')
              .toList();

          if (historyTickets.isEmpty) {
            return _emptyHistory();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: historyTickets.length,
            itemBuilder: (context, index) {
              final t = historyTickets[index];

              final formattedDate =
                  "${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year}";

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: LotteryTicketCard(
                  type: t.type,
                  number: t.number,
                  amount: t.amount,
                  winAmount: t.winAmount,
                  winningNumber: t.winningNumber,
                  date: formattedDate,
                  status: t.status,
                  drawName: "KUBER X",
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 📭 EMPTY STATE
  Widget _emptyHistory() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF6A3D).withOpacity(0.12),
              ),
              child: const Icon(
                Icons.history_toggle_off,
                size: 32,
                color: Color(0xFFFF6A3D),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "No Kuber X History Yet",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your completed tickets will appear here\nonce results are declared.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
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
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ExpansionTile(
          iconColor: const Color(0xFFFF6A3D),
          collapsedIconColor: Colors.grey,

          // ✅ DRAW NAME SHOWN HERE (REQUIREMENT MET)
          title: Text(
            draw.drawName,
            style: const TextStyle(
              color: Color(0xFFFF6A3D),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),

          subtitle: Text(
            "${date.day}/${date.month}/${date.year} • ${tickets.length} ticket(s)",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
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
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
      border: Border.all(color: const Color(0xFFFF6A3D).withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFF6A3D),
              size: 18,
            ),
            SizedBox(width: 6),
            Text(
              "Winning Numbers",
              style: TextStyle(
                color: Color(0xFFFF6A3D),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: results.map((r) {
            return WinChip(label: r.type, number: r.number);
          }).toList(),
        ),
      ],
    ),
  );
}

class WinChip extends StatefulWidget {
  final String label;
  final String number;

  const WinChip({super.key, required this.label, required this.number});

  @override
  State<WinChip> createState() => _WinChipState();
}

class _WinChipState extends State<WinChip> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glowAnimation = Tween<double>(
      begin: 0.2,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6A3D), Color(0xFFFF8A50)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFFFF6A3D,
                  ).withOpacity(_glowAnimation.value),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.label,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
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
      color: winning ? const Color(0xFFE8F5E9) : Colors.white,
      border: Border.all(color: winning ? Colors.green : Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Text(
          t.number,
          style: TextStyle(
            color: winning ? Colors.green.shade800 : Color(0xFF1E1E1E),
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
            color: winning ? Colors.green.shade800 : Colors.red.shade400,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
