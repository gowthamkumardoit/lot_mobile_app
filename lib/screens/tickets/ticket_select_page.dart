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
      backgroundColor: const Color(0xFFFFF8F2),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔙 HEADER BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: Color(0xFF2A2A2A),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      draw.title,
                      style: const TextStyle(
                        color: Color(0xFF2A2A2A),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// 🎯 PAGE TITLE
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Choose Ticket Type",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2A2A2A),
                ),
              ),
            ),

            const SizedBox(height: 4),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Select your preferred entry option",
                style: TextStyle(fontSize: 13, color: Color(0xFF777777)),
              ),
            ),

            const SizedBox(height: 20),

            /// 🎟️ OPTIONS
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (draw.enable2D)
                    _warmTicketCard(
                      title: "2D Ticket",
                      subtitle: "Win x${draw.multiplier2D}",
                      icon: Icons.casino_rounded,
                      accent: const Color(0xFFFF6A00),
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
                    _warmTicketCard(
                      title: "3D Ticket",
                      subtitle: "Win x${draw.multiplier3D}",
                      icon: Icons.confirmation_number_rounded,
                      accent: const Color(0xFFD35400),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ThreeDEntryPage(draw: draw),
                          ),
                        );
                      },
                    ),

                  if (draw.enable4D)
                    _warmTicketCard(
                      title: "4D Ticket",
                      subtitle: "Win x${draw.multiplier4D}",
                      icon: Icons.diamond_rounded,
                      accent: const Color(0xFFD4A017),
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
    );
  }

  Widget _warmTicketCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          border: Border.all(color: accent.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            /// ICON CIRCLE
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.12),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),

            const SizedBox(width: 14),

            /// TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2A2A2A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF777777),
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFFBBBBBB),
            ),
          ],
        ),
      ),
    );
  }
}
