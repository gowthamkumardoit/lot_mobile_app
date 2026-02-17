import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BankAccountForm extends StatefulWidget {
  const BankAccountForm({
    super.key,
    required this.formKey,
    required this.onDataChanged,
  });

  /// Controlled by parent
  final GlobalKey<FormState> formKey;

  /// Emits validated data to parent
  final void Function(Map<String, dynamic> data) onDataChanged;

  @override
  State<BankAccountForm> createState() => _BankAccountFormState();
}

class _BankAccountFormState extends State<BankAccountForm> {
  final _nameCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();

  final _nameRegex = RegExp(r'^[A-Za-z ]+$');
  final _accountNumberRegex = RegExp(r'^[0-9]{6,18}$');
  final _ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
  final _upiRegex = RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$');

  void _emitData() {
    widget.onDataChanged({
      "type": _upiCtrl.text.isNotEmpty ? "UPI" : "BANK",
      "accountHolderName": _nameCtrl.text.trim(),
      "accountNumber": _accountCtrl.text.trim(),
      "ifsc": _ifscCtrl.text.trim().toUpperCase(),
      "upiId": _upiCtrl.text.trim().isEmpty ? null : _upiCtrl.text.trim(),
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _accountCtrl.dispose();
    _ifscCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          _field(
            controller: _nameCtrl,
            label: "Account Holder Name",
            hint: "Name as per bank",
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
            ],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return "Required";
              if (!_nameRegex.hasMatch(v.trim())) {
                return "Only letters and spaces allowed";
              }
              return null;
            },
          ),
          _field(
            controller: _accountCtrl,
            label: "Account Number",
            hint: "Enter bank account number",
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (v == null || v.isEmpty) return "Required";
              if (!_accountNumberRegex.hasMatch(v)) {
                return "Account number must be 6–18 digits";
              }
              return null;
            },
          ),
          _field(
            controller: _ifscCtrl,
            label: "IFSC Code",
            hint: "e.g. HDFC0001234",
            textCapitalization: TextCapitalization.characters,
            validator: (v) {
              if (v == null || v.isEmpty) return "Required";
              if (!_ifscRegex.hasMatch(v.toUpperCase())) {
                return "Invalid IFSC code";
              }
              return null;
            },
          ),
          _field(
            controller: _upiCtrl,
            label: "UPI ID (optional)",
            hint: "example@upi",
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              if (!_upiRegex.hasMatch(v.trim())) {
                return "Invalid UPI ID format";
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            validator: validator,
            onChanged: (_) => _emitData(),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
