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
  final String slotId;
  String? winningNumber;

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
    required this.slotId,
    this.winningNumber,
  });

  factory Ticket.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    return Ticket(
      id: doc.id,
      userId: d['userId'] ?? '',
      number: d['number']?.toString() ?? '--',
      type: d['type'] ?? '2D',

      drawRunId: d['drawRunId'] ?? d['drawId'] ?? '',
      slotId: d['slotId'] ?? '',

      status: d['status'] ?? 'PENDING',

      amount: (d['amount'] ?? 0) is int
          ? d['amount']
          : (d['amount'] ?? 0).toInt(),

      winAmount: (d['winAmount'] ?? 0) is int
          ? d['winAmount']
          : (d['winAmount'] ?? 0).toInt(),

      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),

      // 🔥 CRITICAL FIX
      winningNumber: d['winningNumber']?.toString(),
    );
  }
  Ticket copyWith({String? winningNumber}) {
    return Ticket(
      id: id,
      userId: userId,
      drawRunId: drawRunId,
      slotId: slotId,
      type: type,
      number: number,
      amount: amount,
      winAmount: winAmount,
      status: status,
      createdAt: createdAt,
      winningNumber: winningNumber ?? this.winningNumber,
    );
  }
}
