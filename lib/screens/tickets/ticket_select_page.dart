import 'package:flutter/material.dart';
import 'package:mobile_app/screens/tickets/four_d_entry_page.dart';
import '../../modals/draw_run.dart';
import './two_d_entry_page.dart';
import './three_d_entry_page.dart';

class TicketSelectPage extends StatelessWidget {
  final DrawRun draw;
  const TicketSelectPage({super.key, required this.draw});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B0F2A), Color(0xFF1B0F4A), Color(0xFF2E1A7A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🔙 HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      draw.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🎯 TITLE
              const Text(
                "Choose Your Ticket",
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.cyan, blurRadius: 20)],
                ),
              ),

              const SizedBox(height: 24),

              // 🎟️ OPTIONS
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (draw.enable2D)
                      _ticketCard(
                        title: "2D Ticket",
                        subtitle: "Win x${draw.multiplier2D}",
                        icon: "🎲",
                        color: Colors.orangeAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TwoDEntryPage(draw: draw),
                            ),
                          );
                        },
                      ),

                    if (draw.enable3D)
                      _ticketCard(
                        title: "3D Ticket",
                        subtitle: "Win x${draw.multiplier3D}",
                        icon: "🎰",
                        color: Colors.purpleAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ThreeDEntryPage(draw: draw),
                            ),
                          );
                        },
                      ),

                    // 🆕 4D TICKET
                    if (draw.enable4D)
                      _ticketCard(
                        title: "4D Ticket",
                        subtitle: "Win x${draw.multiplier4D}",
                        icon: "💎",
                        color: Colors.amberAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FourDEntryPage(draw: draw),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ticketCard({
    required String title,
    required String subtitle,
    required String icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.25), color.withOpacity(0.15)],
          ),
          border: Border.all(color: color.withOpacity(0.6)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: -8,
            ),
          ],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
