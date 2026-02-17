import 'package:flutter/material.dart';
import 'package:mobile_app/services/wallet_service.dart';

class UpiSetupSheet extends StatefulWidget {
  const UpiSetupSheet({super.key});

  @override
  State<UpiSetupSheet> createState() => _UpiSetupSheetState();
}

class _UpiSetupSheetState extends State<UpiSetupSheet> {
  static const Color panel = Color(0xFF141B34);
  static const Color accent = Color(0xFF00D9FF);

  final _formKey = GlobalKey<FormState>();

  final _primaryUpiCtrl = TextEditingController();
  final _secondaryUpiCtrl = TextEditingController();

  bool _submitting = false;
  bool _submitted = false;

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    await WalletService.submitUpiAccounts({
      "primaryUpi": _primaryUpiCtrl.text.trim().toLowerCase(),
      "secondaryUpi": _secondaryUpiCtrl.text.trim().isEmpty
          ? null
          : _secondaryUpiCtrl.text.trim().toLowerCase(),
    });

    setState(() {
      _submitting = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, // 🔑 KEY FIX
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // ─── CONTENT ───
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,

                  child: _submitted
                      ? const _PendingState()
                      : Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Add UPI for Withdrawals",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Withdrawals are enabled only after admin approval",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ⚠️ WARNING
                              _warningBox(),

                              const SizedBox(height: 20),

                              // PRIMARY UPI
                              _input(
                                controller: _primaryUpiCtrl,
                                label: "Primary UPI ID",
                                hint: "example@upi",
                                required: true,
                              ),

                              const SizedBox(height: 14),

                              // SECONDARY UPI
                              _input(
                                controller: _secondaryUpiCtrl,
                                label: "Secondary UPI ID (optional)",
                                hint: "example@upi",
                                required: false,
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              // ─── CTA ───
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: const BoxDecoration(
                  color: panel,
                  border: Border(top: BorderSide(color: Colors.white12)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_submitting || _submitted)
                        ? null
                        : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _submitted ? "Submitted" : "Submit for Approval",
                            style: const TextStyle(
                              fontSize: 14,
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

  Widget _input({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool required,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.black),
          validator: (v) {
            if (required && (v == null || v.trim().isEmpty)) {
              return "This field is required";
            }
            if (v != null && v.isNotEmpty && !v.contains('@')) {
              return "Invalid UPI ID";
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _warningBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "⚠️ Please ensure the UPI ID entered is correct.\n\n"
              "We are NOT responsible for failed or incorrect transfers caused by wrong UPI details.",
              style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingState extends StatelessWidget {
  const _PendingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: const [
          SizedBox(height: 60),
          Icon(Icons.hourglass_top, color: Colors.orange, size: 40),
          SizedBox(height: 16),
          Text(
            "UPI details submitted",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "⏳ Under admin review.\nWithdrawals will be enabled after approval.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
