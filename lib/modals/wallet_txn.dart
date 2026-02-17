import 'package:cloud_firestore/cloud_firestore.dart';

class WalletTxn {
  final String id;
  final String userId;
  final int amount; // + credit, - debit
  final String type; // CREDIT / DEBIT
  final String reason; // TICKET, WIN, ADD_MONEY
  final DateTime createdAt;

  WalletTxn({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.reason,
    required this.createdAt,
  });

  factory WalletTxn.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    return WalletTxn(
      id: doc.id,
      userId: d['userId'] ?? '',
      amount: (d['amount'] ?? 0) as int,
      type: d['type'] ?? '',
      reason: d['reason'] ?? '',
      // ✅ SAFE fallback if serverTimestamp not ready
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
