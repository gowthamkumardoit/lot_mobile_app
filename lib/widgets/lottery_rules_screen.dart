import 'package:flutter/material.dart';

class LotteryRulesScreen extends StatelessWidget {
  const LotteryRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Lottery Rules",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F9FF), Color(0xFFEDE7FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const RuleSection(
              title: "1. Eligibility",
              content:
                  "• Users must be 18 years or older.\n"
                  "• Only one account per person.\n"
                  "• Valid mobile number verification required.",
            ),

            const RuleSection(
              title: "2. Account & Wallet",
              content:
                  "• Maintain sufficient wallet balance.\n"
                  "• Bonus balance may have withdrawal conditions.\n"
                  "• Fraudulent accounts will be suspended.",
            ),

            const RuleSection(
              title: "3. Ticket Purchase",
              content:
                  "• Tickets must be purchased before countdown ends.\n"
                  "• Tickets cannot be cancelled or refunded.\n"
                  "• Each ticket is valid only for selected draw.",
            ),

            const RuleSection(
              title: "4. Draw & Result",
              content:
                  "• Results generated via automated system.\n"
                  "• App-declared result is final and binding.\n"
                  "• Draw may be rescheduled if technical issues occur.",
            ),

            const RuleSection(
              title: "5. Winnings & Settlement",
              content:
                  "• Winnings credited automatically.\n"
                  "• Settlement after draw lock.\n"
                  "• Taxes deducted as per law.",
            ),

            const RuleSection(
              title: "6. Withdrawals",
              content:
                  "• Minimum withdrawal may apply.\n"
                  "• Processing time: 24–72 hours.\n"
                  "• Incorrect bank details are user responsibility.",
            ),

            const RuleSection(
              title: "7. Fair Play Policy",
              content:
                  "• Bots & multiple accounts prohibited.\n"
                  "• System exploitation leads to permanent ban.",
            ),

            const RuleSection(
              title: "8. Responsible Gaming",
              content:
                  "• Lottery involves financial risk.\n"
                  "• No guaranteed profit.\n"
                  "• Play responsibly.",
            ),

            const SizedBox(height: 24),

            // ✅ Automatic Consent Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: const Text(
                "By purchasing a ticket or participating in any draw, "
                "you automatically agree to all Lottery Rules, Terms & Conditions, "
                "and Responsible Gaming policies of this platform. "
                "If you do not agree, please refrain from using the app.",
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class RuleSection extends StatelessWidget {
  final String title;
  final String content;

  const RuleSection({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
