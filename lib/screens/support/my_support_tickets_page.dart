import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/services/support_service.dart';

class MySupportTicketsPage extends StatefulWidget {
  const MySupportTicketsPage({super.key});

  @override
  State<MySupportTicketsPage> createState() => _MySupportTicketsPageState();
}

class _MySupportTicketsPageState extends State<MySupportTicketsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Please login again")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F2A),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white, // 👈 makes back arrow visible
        ),
        title: const Text(
          "My Support Tickets",
          style: TextStyle(color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: "OPEN"),
            Tab(text: "CLOSED"),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          _ticketsByStatus(uid, "OPEN"),
          _ticketsByStatus(uid, "CLOSED"),
        ],
      ),
    );
  }

  /// 🔁 Tickets list by status
  Widget _ticketsByStatus(String uid, String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("supportTickets")
          .where("uid", isEqualTo: uid)
          .where("status", isEqualTo: status)
          .orderBy("createdAtClient", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "No $status tickets",
              style: const TextStyle(color: Colors.white54),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final category = data['category'] ?? "GENERAL";
            final message = data['message'] ?? "";
            final adminResponse = data['adminResponse'];

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
                  // HEADER
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

                  const SizedBox(height: 8),

                  // USER MESSAGE
                  const Text(
                    "Your message",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(message, style: const TextStyle(color: Colors.white70)),

                  // ADMIN RESPONSE (ONLY FOR CLOSED)
                  if (status == "CLOSED" &&
                      adminResponse != null &&
                      adminResponse.toString().trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    const Text(
                      "Admin response",
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      adminResponse,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
