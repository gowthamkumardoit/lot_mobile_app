import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/modals/digit_draw_slot.dart';

class DigitDrawSlotService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔥 Get all OPEN slots
  Stream<List<DigitDrawSlot>> getOpenSlots() {
    return _db
        .collection('digitDrawSlots')
        .where('status', isEqualTo: 'OPEN')
        .orderBy('openAt')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => DigitDrawSlot.fromDoc(doc)).toList(),
        );
  }

  /// 📅 Get today's slots (optional if needed)
  Stream<List<DigitDrawSlot>> getTodaySlots() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _db
        .collection('digitDrawSlots')
        .where('openAt', isGreaterThanOrEqualTo: startOfDay)
        .where('openAt', isLessThan: endOfDay)
        .orderBy('openAt')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => DigitDrawSlot.fromDoc(doc)).toList(),
        );
  }

  /// 📌 Get slot by ID
  Future<DigitDrawSlot?> getSlotById(String id) async {
    final doc = await _db.collection('digitDrawSlots').doc(id).get();

    if (!doc.exists) return null;

    return DigitDrawSlot.fromDoc(doc);
  }
}
