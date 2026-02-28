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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Support")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// INFO CARD
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.support_agent,
                      color: theme.colorScheme.primary,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Describe your issue below. Our support team will reply via notification.",
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// LABEL
            Text(
              "Your message",
              style: theme.textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            /// TEXT FIELD
            SizedBox(
              height: 160,
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText:
                      "Example: My withdrawal is still pending from yesterday.",
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// SEND BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _sending || _controller.text.trim().length < 10
                    ? null
                    : _sendMessage,
                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Send Message",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const Spacer(),

            /// FOOTER NOTE
            Center(
              child: Text(
                "Replies will be sent via push notification.",
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontSize: 12,
                  color: Colors.black45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
