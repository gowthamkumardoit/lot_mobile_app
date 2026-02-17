import 'package:cloud_firestore/cloud_firestore.dart';

class Ticket {
  final String id;
  final String userId;
  final String drawRunId;
  final String type; // 2D / 3D
  final String number;
  final int amount;
  final int winAmount; // ✅ ADD THIS
  final String status; // PENDING / WON / LOST
  final DateTime createdAt;

  Ticket({
    required this.id,
    required this.userId,
    required this.drawRunId,
    required this.type,
    required this.number,
    required this.amount,
    required this.winAmount,
    required this.status,
    required this.createdAt,
  });

  factory Ticket.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    return Ticket(
      id: d['id'] ?? doc.id,
      userId: d['userId'] ?? '',
      number: d['number']?.toString() ?? '--',
      type: d['type'] ?? '2D',

      // 🔑 HANDLE BOTH OLD & NEW SCHEMA
      drawRunId: d['drawRunId'] ?? d['drawId'] ?? '',

      status: d['status'] ?? 'PENDING',
      amount: (d['amount'] ?? 0).toInt(),
      winAmount: (d['winAmount'] ?? 0).toInt(),

      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
