import 'package:cloud_firestore/cloud_firestore.dart';
import '../modals/ticket.dart';

class KuberGoldTicketReadService {
  final _db = FirebaseFirestore.instance;

  Stream<List<Ticket>> getUserGoldTickets(String userId) {
    return _db
        .collection("kuberGoldTickets")
        .where("userId", isEqualTo: userId)
        .where("status", isEqualTo: "BOOKED")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();

            return Ticket(
              id: doc.id,
              userId: data["userId"],
              number: data["number"],
              amount: data["amount"],
              winAmount: data["winAmount"],
              type: data["type"],
              status: data["status"],
              createdAt: (data["createdAt"] as Timestamp).toDate(),
              drawRunId: data["slotId"], // slotId used as draw reference
              slotId: data["slotId"], // slotId used as draw reference
            );
          }).toList();
        });
  }
}
