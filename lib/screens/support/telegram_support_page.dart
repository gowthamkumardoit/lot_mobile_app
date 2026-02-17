import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.length < 10) return;

    setState(() => _sending = true);

    try {
      final callable = FirebaseFunctions.instanceFor(
        region: "asia-south1",
      ).httpsCallable("sendSupportMessage");

      await callable.call({"message": text});

      _controller.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Message sent. You’ll be notified when we reply."),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to send message")));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F2A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Support", style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 INFO CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.support_agent, color: Colors.cyanAccent, size: 26),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Describe your issue below. Our support team will reply via notification.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 📝 LABEL
            const Text(
              "Your message",
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 6),

            // 📝 TEXT FIELD (FIXED HEIGHT)
            SizedBox(
              height: 160,
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                onChanged: (_) {
                  setState(() {}); // 🔥 THIS IS THE FIX
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText:
                      "Example: My withdrawal is still pending from yesterday.",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.cyanAccent),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 🚀 SEND BUTTON (RIGHT BELOW TEXT AREA)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.cyanAccent.withOpacity(0.35),
                  disabledForegroundColor: Colors.black54,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _sending || _controller.text.trim().length < 10
                    ? null
                    : _sendMessage,
                child: _sending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        "Send Message",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
              ),
            ),

            const Spacer(),

            // 🔔 FOOTER NOTE
            const Text(
              "Replies will be sent via push notification.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
