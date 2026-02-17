import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/screens/support/my_support_tickets_page.dart';

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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login again")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F2A),
        elevation: 0,
        title: const Text(
          "Support & Help",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            const Text(
              "Need Help?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Submit an issue or track your previous requests.",
              style: TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 20),

            /// CATEGORY
            const Text("Category", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),

            DropdownButtonFormField<String>(
              value: _category,
              dropdownColor: const Color(0xFF151A3A), // 🔑 dropdown list bg
              iconEnabledColor: Colors.cyanAccent,
              style: const TextStyle(color: Colors.white),

              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.cyanAccent),
                ),
              ),

              items: categories
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c,
                      child: Text(
                        c,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),

              onChanged: (v) => setState(() => _category = v!),
            ),

            const SizedBox(height: 20),

            /// MESSAGE
            const Text("Message", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            TextField(
              controller: _messageCtrl,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Describe your issue clearly...",
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),

            const SizedBox(height: 24),

            /// SUBMIT
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const CircularProgressIndicator()
                    : const Text("SUBMIT REQUEST"),
              ),
            ),

            const SizedBox(height: 32),

            /// MY TICKETS
            const SizedBox(height: 32),

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
                  side: const BorderSide(color: Colors.cyanAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "VIEW MY SUPPORT TICKETS",
                  style: TextStyle(color: Colors.cyanAccent),
                ),
              ),
            ),
          ],
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
