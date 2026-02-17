import 'package:cloud_firestore/cloud_firestore.dart';
import '../modals/draw_run.dart';

class DrawService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<DrawRun>> getTodayDraws() {
    final today = _todayDate();

    return _db
        .collection('drawRuns')
        // hide settled
        .where('status', isNotEqualTo: 'SETTLED')
        // only today + future
        .where('date', isGreaterThanOrEqualTo: today)
        // required orderBy
        .orderBy('status')
        .orderBy('date')
        .orderBy('time')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => DrawRun.fromDoc(doc)).toList(),
        );
  }

  String _todayDate() {
    final now = DateTime.now();
    return "${now.year.toString().padLeft(4, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";
  }
}
