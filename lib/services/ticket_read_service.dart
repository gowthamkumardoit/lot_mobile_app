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

  Stream<List<Ticket>> getUserKuberGoldTickets(String uid) {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('kuberGoldTickets')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final tickets = snapshot.docs
              .map((doc) => Ticket.fromDoc(doc))
              .toList();

          // Fetch winning numbers
          final List<Ticket> enrichedTickets = [];

          for (final ticket in tickets) {
            if (ticket.slotId.isEmpty) {
              enrichedTickets.add(ticket);
              continue;
            }

            final slotDoc = await firestore
                .collection('digitDrawSlots')
                .doc(ticket.slotId)
                .get();

            if (!slotDoc.exists) {
              enrichedTickets.add(ticket);
              continue;
            }

            final data = slotDoc.data();
            final result = data?['result'];
            final winningNumber = result?['winningNumber'];

            enrichedTickets.add(
              ticket.copyWith(winningNumber: winningNumber?.toString()),
            );
          }

          return enrichedTickets;
        });
  }
}
