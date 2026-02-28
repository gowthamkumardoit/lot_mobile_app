import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/modals/platform_config.dart';
import 'package:mobile_app/modals/wallet_modal.dart';
import 'package:mobile_app/modals/withdraw_request.dart';
import 'package:mobile_app/screens/wallet/wallet_history_page.dart';
import 'package:mobile_app/services/platform_config_service.dart';
import 'package:mobile_app/services/user_service.dart';
import 'package:mobile_app/services/wallet_service.dart';
import 'package:mobile_app/modals/wallet_txn.dart';
import 'package:mobile_app/modals/topup_request.dart';
import 'package:mobile_app/screens/wallet/topup_bottom_sheet.dart';
import 'package:mobile_app/screens/wallet/withdraw/withdraw_bottom_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const walletBg = Color(0xFF0B1220);
const walletSurface = Color(0xFF11172C);
const walletCardDark = Color(0xFF141B34);
const walletAccent = Color(0xFF3B6CFF);
const walletAccent2 = Color(0xFF00E5FF);
const walletCredit = Color(0xFF2EFF7A);
const walletDebit = Color(0xFFFF5C5C);

bool isWithdrawBlocked({
  required PlatformConfig config,
  required bool userKycApproved,
}) {
  // Global emergency stop
  if (config.withdrawalsDisabled) return true;

  // KYC required for ANY withdrawal
  if (config.kyc.requiredForWithdrawals && !userKycApproved) {
    return true;
  }

  // ❌ DO NOT check requiredAboveAmount here
  return false;
}

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  Key _refreshKey = UniqueKey();

  Future<void> _handleRefresh() async {
    setState(() {
      _refreshKey = UniqueKey(); // rebuild everything
    });

    await Future.delayed(const Duration(milliseconds: 600));
  }

  // THEME

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: walletBg,
        body: Center(
          child: Text(
            "Please login to view wallet",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final userId = user.uid;

    return Scaffold(
      backgroundColor: walletBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: walletAccent2,
          onRefresh: _handleRefresh,
          child: ListView(
            key: _refreshKey,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "My Wallet",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WalletHistoryPage(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.history, size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              "History",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // HERO BALANCE CARD
              StreamBuilder<PlatformConfig>(
                stream: PlatformConfigService().streamConfig(),
                builder: (context, configSnap) {
                  if (!configSnap.hasData) {
                    return const SizedBox(height: 160);
                  }

                  final config = configSnap.data!;

                  return StreamBuilder<bool>(
                    stream: UserService().streamKycApproved(userId),
                    builder: (context, kycSnap) {
                      final kycApproved = kycSnap.data ?? false;

                      return StreamBuilder<WalletBalance>(
                        stream: WalletService().getWalletBalances(userId),
                        builder: (context, balanceSnap) {
                          final balance =
                              balanceSnap.data ??
                              WalletBalance(wallet: 0, locked: 0, bonus: 0);

                          final blocked = isWithdrawBlocked(
                            config: config,
                            userKycApproved: kycApproved,
                          );

                          return _WalletHeroCard(
                            balance: balance,
                            withdrawBlocked: blocked,
                            config: config,
                            kycApproved: kycApproved,
                          );
                        },
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),

              // PENDING TOPUPS
              StreamBuilder<List<TopupRequest>>(
                stream: WalletService().getPendingTopups(userId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final r = snapshot.data!.first;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orange.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_top, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "₹${r.amount} Top-up Pending",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "UTR: ${r.utr}",
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          "Submitted",
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // 🔒 PENDING WITHDRAWAL
              StreamBuilder<WithdrawRequest?>(
                stream: WalletService().getPendingWithdrawal(userId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const SizedBox.shrink();
                  }

                  final w = snapshot.data!;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.hourglass_top,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "₹${w.amount} Withdrawal Pending",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "Processing to your ${w.method}",
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          "Processing",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // RECENT ACTIVITY
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Recent Activity",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: walletSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: StreamBuilder<List<WalletTxn>>(
                  stream: WalletService().getWalletTxns(userId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: Text(
                            "No transactions yet",
                            style: TextStyle(color: Colors.white38),
                          ),
                        ),
                      );
                    }

                    final txns = snapshot.data!;
                    return Column(
                      children: txns.map((t) {
                        final isCredit = t.amount > 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: isCredit ? walletCredit : walletDebit,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.reason,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      "${t.createdAt}",
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "${isCredit ? '+' : '-'}₹${t.amount.abs()}",
                                style: TextStyle(
                                  color: isCredit ? walletCredit : walletDebit,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WalletHistoryPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "View Full History",
                      style: TextStyle(
                        color: walletAccent2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletHeroCard extends StatelessWidget {
  final WalletBalance balance;
  final bool withdrawBlocked;
  final PlatformConfig config;
  final bool kycApproved;

  const _WalletHeroCard({
    required this.balance,
    required this.withdrawBlocked,
    required this.config,
    required this.kycApproved,
  });

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [walletAccent, walletAccent2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          /// ₹ WATERMARK
          Positioned(
            right: -10,
            bottom: -30,
            child: Opacity(
              opacity: 0.08,
              child: Text(
                "₹",
                style: TextStyle(
                  fontSize: 200,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Available Balance",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                "₹ ${balance.available}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                ),
              ),

              if (balance.locked > 0) ...[
                const SizedBox(height: 6),
                Text(
                  "₹${balance.locked} locked in pending withdrawal",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],

              /// 🎁 BONUS STREAM SECTION
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('bonuses')
                    .where('status', isEqualTo: 'ACTIVE')
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return const SizedBox();
                  }

                  final docs = snap.data!.docs;

                  int totalBonus = 0;
                  DateTime? earliestExpiry;

                  for (final doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;

                    final remaining = (data['remaining'] ?? 0) as num;
                    final expiresAt = (data['expiresAt'] as Timestamp?)
                        ?.toDate();

                    totalBonus += remaining.toInt();

                    if (expiresAt != null) {
                      if (earliestExpiry == null ||
                          expiresAt.isBefore(earliestExpiry)) {
                        earliestExpiry = expiresAt;
                      }
                    }
                  }

                  if (totalBonus <= 0) return const SizedBox();

                  final expiryText = _formatExpiry(earliestExpiry);

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.card_giftcard,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),

                        /// Bonus + Countdown
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              Text(
                                "Bonus ₹$totalBonus",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),

                              if (earliestExpiry != null) ...[
                                const Text(
                                  "•",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                BonusCountdown(expiry: earliestExpiry),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              if (withdrawBlocked) ...[
                const SizedBox(height: 14),
                _WithdrawBlockedBanner(config: config),
              ],

              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: _ActionPill(
                      icon: Icons.add,
                      label: "Top Up",
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const TopUpBottomSheet(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionPill(
                      icon: Icons.arrow_upward,
                      label: "Withdraw",
                      onTap: withdrawBlocked
                          ? () => _showWithdrawBlocked(context, config)
                          : () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => WithdrawBottomSheet(
                                  config: config,
                                  kycApproved: kycApproved,
                                ),
                              );
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _formatExpiry(DateTime? expiry) {
    if (expiry == null) return null;

    final diff = expiry.difference(DateTime.now());

    if (diff.isNegative) return "Expired";

    final days = diff.inDays;
    final hours = diff.inHours % 24;

    if (days > 0) {
      return "Expires in ${days}d ${hours}h";
    } else {
      return "Expires in ${diff.inHours}h";
    }
  }
}

void _showWithdrawBlocked(BuildContext context, PlatformConfig config) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF141B34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Withdrawal Restricted",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          config.withdrawalsDisabled
              ? "Withdrawals are temporarily disabled by the platform."
              : "Please complete KYC to withdraw your balance.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}

class BonusCountdown extends StatefulWidget {
  final DateTime expiry;

  const BonusCountdown({super.key, required this.expiry});

  @override
  State<BonusCountdown> createState() => _BonusCountdownState();
}

class _BonusCountdownState extends State<BonusCountdown> {
  late Duration remaining;

  @override
  void initState() {
    super.initState();
    remaining = widget.expiry.difference(DateTime.now());
    _startTicker();
  }

  void _startTicker() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        remaining = widget.expiry.difference(DateTime.now());
      });

      return !remaining.isNegative;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (remaining.isNegative) {
      return const Text(
        "Expired",
        style: TextStyle(
          color: Color.fromARGB(255, 255, 254, 254),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      );
    }

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    String text;

    if (days > 0) {
      text = "Expires in ${days}d ${hours}h ${minutes}m";
    } else {
      text =
          " Expires in  ${hours.toString().padLeft(2, '0')}:"
          "${minutes.toString().padLeft(2, '0')}:"
          "${seconds.toString().padLeft(2, '0')}";
    }

    return Text(
      text,
      style: TextStyle(
        color: days == 0 ? Colors.redAccent : Colors.orangeAccent,
        fontWeight: FontWeight.w700,
        fontSize: 13,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _WithdrawBlockedBanner extends StatelessWidget {
  final PlatformConfig config;

  const _WithdrawBlockedBanner({required this.config});

  @override
  Widget build(BuildContext context) {
    String message = "Withdrawals are currently unavailable";

    if (config.withdrawalsDisabled) {
      message = "Withdrawals are temporarily disabled";
    } else if (config.kyc.requiredForWithdrawals) {
      message = "Complete KYC to withdraw funds";
    } else {
      message =
          "KYC required for withdrawals above ₹${config.kyc.requiredAboveAmount}";
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionPill({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
