import 'package:flutter/material.dart';

class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.build, size: 48, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              "Maintenance in progress",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "We’ll be back shortly.\nPlease try again later.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
