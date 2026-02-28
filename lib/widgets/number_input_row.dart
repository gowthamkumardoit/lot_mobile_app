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
    return Row(
      children: [
        /// 🔢 NUMBER FIELD
        Expanded(
          child: TextField(
            controller: controller,
            maxLength: digits,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],

            style: const TextStyle(
              color: Color(0xFF2A2A2A),
              fontSize: 18,
              letterSpacing: 6,
              fontWeight: FontWeight.w700,
            ),

            decoration: InputDecoration(
              counterText: '',
              hintText: List.filled(digits, "0").join(),
              hintStyle: const TextStyle(
                color: Color(0xFFB0B0B0),
                letterSpacing: 6,
              ),

              filled: true,
              fillColor: const Color(0xFFFFF1E6),

              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),

              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: Color(0xFFFF6A00),
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(14),
              ),

              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: Color(0xFFFF6A00),
                  width: 1.6,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        /// ➕ ADD BUTTON
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6A00),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "Add",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
