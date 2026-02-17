import 'package:cloud_firestore/cloud_firestore.dart';
import '../modals/ticket.dart';

class TicketReadService {
  final _db = FirebaseFirestore.instance;

  Stream<List<Ticket>> getUserTickets(String userId) {
    return _db
        .collection('tickets')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Ticket.fromDoc(d)).toList());
  }

  Stream<List<Ticket>> getActiveTickets(String userId) {
    return _db
        .collection('tickets')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'PENDING') // ✅ ONLY ACTIVE
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Ticket.fromDoc(d)).toList());
  }
}
