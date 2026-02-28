import 'package:cloud_firestore/cloud_firestore.dart';

class DigitDrawSlot {
  final String id;
  final String name;
  final int digits;
  final String status;
  final DateTime openAt;
  final DateTime createdAt;
  final DateTime closeAt;
  final int ticketPrice;
  final int totalCombinations;
  final Map<String, dynamic> prizes;

  DigitDrawSlot({
    required this.id,
    required this.name,
    required this.digits,
    required this.status,
    required this.openAt,
    required this.createdAt,
    required this.closeAt,
    required this.ticketPrice,
    required this.totalCombinations,
    required this.prizes,
  });

  factory DigitDrawSlot.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return DigitDrawSlot(
      id: doc.id,
      name: data['name'] ?? '',
      digits: data['digits'] ?? 0,
      status: data['status'] ?? '',
      openAt: (data['openAt'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      closeAt: (data['closeAt'] as Timestamp).toDate(),
      ticketPrice: data['configSnapshot']?['ticketPrice'] ?? 0,
      totalCombinations: data['stats']?['totalCombinations'] ?? 0,
      prizes: data['configSnapshot']?['prizes'] ?? {},
    );
  }
}
