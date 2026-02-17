import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawRequest {
  final String id;
  final int amount;
  final String method; // UPI / BANK
  final String status; // SUBMITTED / APPROVED / REJECTED
  final DateTime createdAt;

  WithdrawRequest({
    required this.id,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
  });

  factory WithdrawRequest.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return WithdrawRequest(
      id: doc.id,
      amount: data['amount'] ?? 0,
      method: data['method'] ?? 'UPI',
      status: data['status'] ?? 'SUBMITTED',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
