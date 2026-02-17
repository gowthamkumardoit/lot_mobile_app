import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/modals/platform_config.dart';
import 'package:mobile_app/modals/withdraw_request.dart';
import 'package:mobile_app/screens/wallet/bank/bank_account_setup_sheet.dart';
import 'package:mobile_app/services/user_service.dart';
import 'package:mobile_app/services/wallet_service.dart';
import 'package:flutter/services.dart';

class WithdrawBottomSheet extends StatefulWidget {
  final PlatformConfig config;
  final bool kycApproved;

  const WithdrawBottomSheet({
    super.key,
    required this.config,
    required this.kycApproved,
  });

  @override
  State<WithdrawBottomSheet> createState() => _WithdrawBottomSheetState();
}

class _WithdrawBottomSheetState extends State<WithdrawBottomSheet> {
  final _amountCtrl = TextEditingController();

  static const bg = Color(0xFF0B1220);
  static const panel = Color(0xFF141B34);
  static const accent = Color(0xFF00D9FF);
  static const danger = Color(0xFFFF5C5C);

  bool _loading = false;
  bool _checkingBank = true;

  String? _bankStatus; // NONE | PENDING | APPROVED | REJECTED
  String? _primaryUpi;
  String? _secondaryUpi;

  int _walletBalance = 0;
  int _lockedBalance = 0;
  int get _availableBalance =>
      (_walletBalance - _lockedBalance).clamp(0, _walletBalance);

  late final PlatformConfig config;
  late bool _kycApproved;

  @override
  void initState() {
    super.initState();
    config = widget.config;
    _kycApproved = widget.kycApproved;

    _loadBankStatus();
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    final data = await WalletService.getWalletBalances();
    if (!mounted) return;

    setState(() {
      _walletBalance = data['wallet']!;
      _lockedBalance = data['locked']!;
    });
  }

  Future<void> _loadBankStatus() async {
    final data = await WalletService.getLatestUpiAccounts();
    if (!mounted) return;

    if (data == null) {
      // No UPI submitted at all
      setState(() {
        _bankStatus = "NONE";
        _primaryUpi = null;
        _secondaryUpi = null;

        _checkingBank = false;
      });
      return;
    }

    final status = (data['status'] as String?)?.toUpperCase() ?? "PENDING";

    setState(() {
      _bankStatus = status;
      _primaryUpi = data['primaryUpi'];
      _secondaryUpi = data['secondaryUpi'];
      // 🔑 FIXED FIELD
      _checkingBank = false;
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _openBankSetup() async {
    if (_bankStatus == "PENDING") {
      _showError("UPI request is under review. Please wait for approval.");
      return;
    }

    if (_bankStatus == "APPROVED") {
      _showError("UPI already approved. You cannot change it.");
      return;
    }

    // Close withdraw sheet
    Navigator.pop(context);

    // Open UPI setup
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UpiSetupSheet(),
    );

    // Reopen withdraw sheet
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          WithdrawBottomSheet(config: config, kycApproved: _kycApproved),
    );
  }

  Future<void> _submitWithdraw() async {
    final raw = _amountCtrl.text.trim();
    final amount = int.tryParse(raw);

    if (amount == null || amount <= 0) {
      _showError("Enter a valid amount");
      return;
    }

    final config = this.config;

    if (amount < config.minWithdrawal) {
      _showError("Minimum withdrawal is ₹${config.minWithdrawal}");
      return;
    }

    // ✅ KYC CHECK
    if (!_kycApproved && amount > config.kyc.requiredAboveAmount) {
      _showError(
        "KYC is required to withdraw more than ₹${config.kyc.requiredAboveAmount}",
      );
      return;
    }

    setState(() => _loading = true);

    final pending = await WalletService()
        .getPendingWithdrawal(FirebaseAuth.instance.currentUser!.uid)
        .first;

    if (pending != null) {
      _showError("You already have a withdrawal in progress");
      setState(() => _loading = false);
      return;
    }

    if (amount > _availableBalance) {
      _showError("Insufficient available balance");
      setState(() => _loading = false);
      return;
    }

    try {
      await WalletService.createWithdrawAmountRequest(amount: amount);

      if (!mounted) return;
      Navigator.pop(context);
      _amountCtrl.clear();
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      useRootNavigator: true, // 🔑 VERY IMPORTANT
      builder: (ctx) => AlertDialog(
        backgroundColor: panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          "Action Required",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteUpi() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: panel,
        title: const Text("Delete UPI?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "This will remove all your UPI details.\nYou will need to add them again to withdraw.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("DELETE", style: TextStyle(color: danger)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteUpi();
    }
  }

  Future<void> _deleteUpi() async {
    try {
      setState(() => _loading = true);

      await WalletService.deleteUpiAccounts();

      if (!mounted) return;

      setState(() {
        _bankStatus = "NONE";
        _primaryUpi = null;
        _secondaryUpi = null;
        _loading = false;
      });

      _showError("UPI deleted successfully");
    } catch (e) {
      setState(() => _loading = false);
      _showError("Failed to delete UPI. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe =
        MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomSafe + 20),
      decoration: const BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: (_checkingBank)
          ? const Center(child: CircularProgressIndicator())
          : config.withdrawalsDisabled
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Handle(),
                const SizedBox(height: 20),
                _infoBox(
                  icon: Icons.block,
                  color: danger,
                  text: "Withdrawals are temporarily disabled",
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Handle(),
                const SizedBox(height: 18),
                const Text(
                  "Withdraw Funds",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // 💰 AVAILABLE BALANCE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Available Balance",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    Text(
                      "₹$_availableBalance",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                // 🔒 LOCKED INFO (optional but recommended)
                if (_lockedBalance > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    "₹$_lockedBalance locked in pending withdrawal",
                    style: const TextStyle(color: Colors.orange, fontSize: 11),
                  ),
                ],

                const SizedBox(height: 14),

                StreamBuilder<WithdrawRequest?>(
                  stream: WalletService().getPendingWithdrawal(
                    FirebaseAuth.instance.currentUser!.uid,
                  ),
                  builder: (context, snapshot) {
                    final hasPending =
                        snapshot.hasData && snapshot.data != null;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 BANK / UPI SECTION
                        _buildBankSection(hasPendingWithdrawal: hasPending),

                        const SizedBox(height: 14),

                        // 🔒 PENDING WITHDRAWAL MESSAGE
                        if (hasPending)
                          _infoBox(
                            icon: Icons.hourglass_top,
                            color: Colors.orange,
                            text:
                                "You already have a withdrawal in progress.\nPlease wait until it is completed.",
                          ),

                        // 💰 WITHDRAW FORM (only if allowed)
                        if (!hasPending && _bankStatus == "APPROVED") ...[
                          if (_availableBalance == 0) ...[
                            const SizedBox(height: 8),
                            const Text(
                              "No available balance to withdraw",
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ],

                          const SizedBox(height: 14),

                          _Input(
                            controller: _amountCtrl,
                            hint: "Enter withdraw amount",
                            prefix: "₹",
                            keyboardType: TextInputType.number,
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: (_loading || _availableBalance == 0)
                                  ? null
                                  : _submitWithdraw,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: bg,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Request Withdrawal",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                if (_availableBalance == 0) ...[
                  const SizedBox(height: 8),
                  const Text(
                    "No available balance to withdraw",
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildUpiCard({required bool hasPendingWithdrawal}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.verified, color: Colors.green, size: 18),
              SizedBox(width: 8),
              Text(
                "UPI Verified",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _upiRow(label: "Primary UPI", value: _primaryUpi),

          if (_secondaryUpi != null && _secondaryUpi!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _upiRow(label: "Secondary UPI", value: _secondaryUpi),
          ],

          const SizedBox(height: 14),

          if (!hasPendingWithdrawal)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _loading ? null : _confirmDeleteUpi,
                icon: const Icon(Icons.delete, color: danger, size: 18),
                label: const Text(
                  "DELETE UPI",
                  style: TextStyle(color: danger),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                "UPI cannot be modified while a withdrawal is in progress",
                style: TextStyle(color: Colors.orange, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _upiRow({required String label, String? value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value ?? "-",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBankSection({required bool hasPendingWithdrawal}) {
    switch (_bankStatus) {
      case "APPROVED":
        return _buildUpiCard(hasPendingWithdrawal: hasPendingWithdrawal);

      case "REJECTED":
        return _infoBox(
          icon: Icons.error,
          color: danger,
          text:
              "UPI details rejected.\nPlease resubmit correct UPI information.",
          action: TextButton(
            onPressed: _openBankSetup,
            child: const Text("RESUBMIT"),
          ),
        );

      case "NONE":
        return _infoBox(
          icon: Icons.warning_amber_rounded,
          color: danger,
          text: "UPI not added",
          action: TextButton(
            onPressed: _openBankSetup,
            child: const Text("ADD NOW"),
          ),
        );

      case "PENDING":
      default:
        return _infoBox(
          icon: Icons.hourglass_top,
          color: Colors.orange,
          text:
              "UPI details are under review.\nYou cannot modify them until approval.",
        );
    }
  }

  Widget _infoBox({
    required IconData icon,
    required Color color,
    required String text,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? prefix;
  final TextInputType keyboardType;

  const _Input({
    required this.controller,
    required this.hint,
    this.prefix,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly, // ✅ ONLY NUMBERS
        LengthLimitingTextInputFormatter(7), // optional: max digits
      ],
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixText: prefix,
        prefixStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
