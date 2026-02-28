import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/screens/support/my_support_tickets_page.dart';
import 'package:flutter/services.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _messageCtrl = TextEditingController();
  bool _submitting = false;

  String _category = "GENERAL";

  final categories = const [
    "GENERAL",
    "PAYMENT",
    "KYC",
    "TICKETS",
    "TECHNICAL",
  ];

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _messageCtrl.text.trim().isEmpty) return;

    setState(() => _submitting = true);

    final userSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final username = userSnap.data()?['username'] ?? "unknown";

    await FirebaseFirestore.instance.collection("supportTickets").add({
      "uid": user.uid,
      "username": username,
      "category": _category,
      "message": _messageCtrl.text.trim(),
      "status": "OPEN",
      "createdAt": FieldValue.serverTimestamp(),
      "createdAtClient": Timestamp.now(),
    });

    _messageCtrl.clear();
    setState(() => _submitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Support request submitted")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login again")));
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Android
        statusBarBrightness: Brightness.light, // iOS
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Support & Help"),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Need Help?", style: theme.textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                "Submit an issue or track your previous requests.",
                style: theme.textTheme.bodyMedium,
              ),

              const SizedBox(height: 24),

              /// CATEGORY
              Text("Category", style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),

              const SizedBox(height: 20),

              /// MESSAGE
              Text("Message", style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),

              TextField(
                controller: _messageCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: "Describe your issue clearly...",
                ),
              ),

              const SizedBox(height: 28),

              /// SUBMIT
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("SUBMIT REQUEST"),
                ),
              ),

              const SizedBox(height: 40),

              /// VIEW TICKETS
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MySupportTicketsPage(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    "VIEW MY SUPPORT TICKETS",
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔁 TICKETS LIST
  Widget _ticketsList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("supportTickets")
          .where("uid", isEqualTo: uid)
          .orderBy("createdAtClient", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "No support tickets yet.",
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? "OPEN";
            final category = data['category'] ?? "GENERAL";
            final message = data['message'] ?? "";

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        status,
                        style: TextStyle(
                          color: status == "OPEN"
                              ? Colors.orangeAccent
                              : Colors.greenAccent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// QUICK HELP ROW
  Widget _quickHelpRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                value,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
