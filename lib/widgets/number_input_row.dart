import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumberInputRow extends StatelessWidget {
  final TextEditingController controller;
  final int digits;
  final VoidCallback onAdd;

  const NumberInputRow({
    super.key,
    required this.controller,
    required this.digits,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLength: digits,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                letterSpacing: 4,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: List.filled(digits, "0").join(), // ✅ FIX
                hintStyle: const TextStyle(color: Colors.white38),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.cyanAccent),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.cyanAccent),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(onPressed: onAdd, child: const Text("ADD")),
        ],
      ),
    );
  }
}
