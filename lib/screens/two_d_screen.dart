import 'package:flutter/material.dart';
import 'stake_screen.dart';

class TwoDScreen extends StatefulWidget {
  const TwoDScreen({super.key});

  @override
  State<TwoDScreen> createState() => _TwoDScreenState();
}

class _TwoDScreenState extends State<TwoDScreen> {
  // selected numbers
  final Set<int> selected = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick 2D Number"),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.2,
          ),
          itemCount: 100,
          itemBuilder: (context, index) {
            final number = index; // 0 → 99
            final formatted = number.toString().padLeft(2, '0');
            final isSelected = selected.contains(number);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selected.remove(number);
                  } else {
                    selected.add(number);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.purpleAccent : Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.cyanAccent : Colors.grey,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          const BoxShadow(
                            color: Colors.purpleAccent,
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    formatted,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black,
        child: ElevatedButton(
          onPressed: selected.isEmpty
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          StakeScreen(selectedNumbers: selected.toList()),
                    ),
                  );
                },

          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purpleAccent,
            disabledBackgroundColor: Colors.grey,
          ),
          child: Text(
            selected.isEmpty
                ? "Pick numbers"
                : "Continue (${selected.length} selected)",
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
