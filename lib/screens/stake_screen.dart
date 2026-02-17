import 'package:flutter/material.dart';

class StakeScreen extends StatefulWidget {
  final List<int> selectedNumbers;

  const StakeScreen({super.key, required this.selectedNumbers});

  @override
  State<StakeScreen> createState() => _StakeScreenState();
}

class _StakeScreenState extends State<StakeScreen> {
  final TextEditingController amountCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Enter Stake Amount"),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Selected Numbers:", style: const TextStyle(fontSize: 20)),
            Wrap(
              spacing: 8,
              children: widget.selectedNumbers
                  .map(
                    (n) => Chip(
                      label: Text(n.toString().padLeft(2, "0")),
                      backgroundColor: Colors.purpleAccent,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 30),

            // Stake input
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Enter stake (₹)",
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 22),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (amountCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Enter an amount!")),
                    );
                    return;
                  }

                  final stake = double.tryParse(amountCtrl.text);
                  if (stake == null || stake <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Invalid amount")),
                    );
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Placed ₹${amountCtrl.text} on ${widget.selectedNumbers.length} numbers",
                      ),
                    ),
                  );

                  Navigator.pop(context); // later -> push payment
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.purpleAccent,
                ),
                child: const Text(
                  "CONFIRM BET",
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
