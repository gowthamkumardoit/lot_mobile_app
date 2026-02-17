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

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  // THEME
  static const bg = Color(0xFF0B1220);
  static const surface = Color(0xFF11172C);
  static const cardDark = Color(0xFF141B34);
  static const accent = Color(0xFF3B6CFF);
  static const accent2 = Color(0xFF00E5FF);
  static const credit = Color(0xFF2EFF7A);
  static const debit = Color(0xFFFF5C5C);
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: bg,
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
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        stream: WalletService().getWalletBalanceStream(userId),
                        builder: (context, balanceSnap) {
                          final balance =
                              balanceSnap.data ??
                              WalletBalance(wallet: 0, locked: 0);

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
                  color: surface,
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
                                  color: isCredit ? credit : debit,
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
                                  color: isCredit ? credit : debit,
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
                        color: accent2,
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
  final bool kycApproved; // ✅ ADD

  const _WalletHeroCard({
    required this.balance,
    required this.withdrawBlocked,
    required this.config,
    required this.kycApproved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [WalletPage.accent, WalletPage.accent2],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Available Balance",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text(
            "₹ ${balance.available}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
            ),
          ),

          if (balance.locked > 0) ...[
            const SizedBox(height: 6),
            Text(
              "₹${balance.locked} locked in pending withdrawal",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],

          if (withdrawBlocked) ...[
            const SizedBox(height: 12),
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
    );
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
