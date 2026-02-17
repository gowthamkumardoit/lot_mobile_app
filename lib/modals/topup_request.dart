import 'package:cloud_firestore/cloud_firestore.dart';

class TopupRequest {
  final String id;
  final int amount;
  final String utr;
  final String status;
  final DateTime createdAt;

  TopupRequest({
    required this.id,
    required this.amount,
    required this.utr,
    required this.status,
    required this.createdAt,
  });

  factory TopupRequest.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TopupRequest(
      id: doc.id,
      amount: data['amount'] ?? 0,
      utr: data['utr'] ?? '',
      status: data['status'] ?? 'SUBMITTED',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
