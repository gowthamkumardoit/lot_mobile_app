import 'package:flutter/material.dart';

class BankAccountWarning extends StatelessWidget {
  const BankAccountWarning({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        "⚠️ Changing or deleting bank / UPI details requires re-approval and may delay withdrawals.",
        style: TextStyle(color: Colors.orange, fontSize: 12),
      ),
    );
  }
}
