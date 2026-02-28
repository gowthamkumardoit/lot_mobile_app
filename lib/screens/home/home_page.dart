import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_app/modals/draw_run.dart';
import 'package:mobile_app/screens/home/lucky_draw_card.dart';
import 'package:mobile_app/services/draw_run_service.dart';
import 'package:mobile_app/services/wallet_service.dart';
import 'package:mobile_app/widgets/digit_slot_card.dart';
import 'package:mobile_app/widgets/lottery_header.dart';
import '../../services/digit_draw_slot_service.dart';
import '../../modals/digit_draw_slot.dart';
import '../../theme/app_gradients.dart';
import 'package:intl/intl.dart';
import '../../pages/ticket_purchase_page.dart';
import '../../widgets/promotion_carousel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Key _refreshKey = UniqueKey();

  Future<void> _handleRefresh() async {
    // Optional: clear caches if you use them
    // DrawResultService.clearCache();

    // Force rebuild to re-trigger streams
    setState(() {
      _refreshKey = UniqueKey();
    });

    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    final WalletService _walletService = WalletService();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    final userId = user.uid; // now non-null String

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA), // 🔥 light theme bg
        body: SafeArea(
          child: StreamBuilder<List<DigitDrawSlot>>(
            stream: DigitDrawSlotService().getOpenSlots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    snapshot.error.toString(),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              }

              // if (!snapshot.hasData || snapshot.data!.isEmpty) {
              //   return noDrawsAvailable(context);
              // }

              return DefaultTabController(
                length: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    /// ✅ HEADER ALWAYS VISIBLE
                    WalletHeaderWrapper(userId: userId),

                    const SizedBox(height: 12),

                    Expanded(
                      child: NestedScrollView(
                        key: _refreshKey,
                        physics: const AlwaysScrollableScrollPhysics(),
                        headerSliverBuilder: (context, innerBoxIsScrolled) => [
                          const SliverToBoxAdapter(
                            child: Column(
                              children: [
                                PromotionCarousel(height: 200),
                                SizedBox(height: 16),
                              ],
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(
                                    255,
                                    0,
                                    47,
                                    255,
                                  ).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Color.fromARGB(
                                      255,
                                      0,
                                      47,
                                      255,
                                    ).withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.card_giftcard,
                                      size: 18,
                                      color: Color.fromARGB(255, 0, 47, 255),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Bonus is applicable only for Kuber Gold draws",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color.fromARGB(
                                            255,
                                            0,
                                            47,
                                            255,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _TabBarDelegate(
                              TabBar(
                                indicatorColor: Color(0xFFFF6A3D),
                                indicatorWeight: 3,
                                labelColor: Color(0xFF1E1E1E),
                                unselectedLabelColor: Colors.grey,
                                tabs: [
                                  Tab(text: "Kuber Gold"),
                                  Tab(text: "Kuber X"),
                                ],
                              ),
                            ),
                          ),
                        ],
                        body: TabBarView(
                          children: [
                            _GoldTab(), // Gold handles its own empty
                            _KuberXTab(), // Kuber X handles its own empty
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFF5F6FA),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

class _GoldTab extends StatelessWidget {
  const _GoldTab({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // force rebuild
        (context.findAncestorStateOfType<_HomePageState>())?.setState(() {});
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: StreamBuilder<List<DigitDrawSlot>>(
        stream: DigitDrawSlotService().getOpenSlots(),
        builder: (context, snapshot) {
          /// 🔄 Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          /// ❌ Error
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Something went wrong",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          /// 📦 Data
          final slots = snapshot.data ?? [];

          if (slots.isEmpty) {
            return _emptyKuberGold();
          }

          /// 🔥 List
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
            itemCount: slots.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              return DigitSlotCard(
                key: ValueKey(slots[i].id), // important for proper rebuild
                slot: slots[i],
              );
            },
          );
        },
      ),
    );
  }
}

class _KuberXTab extends StatelessWidget {
  final DrawService _drawService = DrawService();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        (context.findAncestorStateOfType<_HomePageState>())?.setState(() {});
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: StreamBuilder<List<DrawRun>>(
        stream: _drawService.getTodayDraws(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Something went wrong",
                style: TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final draws = snapshot.data ?? [];

          if (draws.isEmpty) {
            return _emptyKuberX();
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: draws.length,
            itemBuilder: (context, index) {
              return LuckyDrawCard(draw: draws[index]);
            },
          );
        },
      ),
    );
  }
}

class WalletHeaderWrapper extends StatelessWidget {
  final String userId;

  const WalletHeaderWrapper({super.key, required this.userId});

  Future<String?> _getAvatarUrl() async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'profile_photos/$userId/avatar',
      );

      return await ref.getDownloadURL();
    } catch (e) {
      return null; // if image doesn't exist
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getAvatarUrl(),
      builder: (context, avatarSnapshot) {
        final avatarUrl = avatarSnapshot.data;

        return StreamBuilder<int>(
          stream: WalletService().getBalance(userId),
          builder: (context, snapshot) {
            final balance = snapshot.data ?? 0;

            return LotteryHeader(
              balance: "₹${NumberFormat('#,##,###').format(balance)}",
              notificationCount: 0,
              avatarUrl: avatarUrl, // ✅ pass image
            );
          },
        );
      },
    );
  }
}

Widget _buildCountdown(DateTime closeTime) {
  return StreamBuilder<int>(
    stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
    builder: (context, snapshot) {
      final now = DateTime.now();
      final difference = closeTime.difference(now);

      if (difference.isNegative) {
        return const Text(
          "Closed",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        );
      }

      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      final seconds = difference.inSeconds % 60;

      return Row(
        children: [
          const Icon(Icons.timer_outlined, size: 16, color: Colors.redAccent),
          const SizedBox(width: 6),
          Text(
            "${hours.toString().padLeft(2, '0')}:"
            "${minutes.toString().padLeft(2, '0')}:"
            "${seconds.toString().padLeft(2, '0')}",
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.redAccent,
            ),
          ),
        ],
      );
    },
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

Widget _emptyKuberGold() {
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
            blurRadius: 16,
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
              Icons.event_busy_outlined,
              size: 32,
              color: Color(0xFFFF6A3D),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "No Kuber Gold Draws",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "New Kuber Gold draws will appear here.\nPlease check back shortly.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
          ),
        ],
      ),
    ),
  );
}

Widget _emptyKuberX() {
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
            blurRadius: 16,
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
              Icons.event_busy_outlined,
              size: 32,
              color: Color(0xFFFF6A3D),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "No Kuber X Draws",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "New Kuber X draws will appear here.\nPlease check back shortly.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
          ),
        ],
      ),
    ),
  );
}
