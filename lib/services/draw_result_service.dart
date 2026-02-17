import 'package:cloud_firestore/cloud_firestore.dart';
import '../modals/draw_result.dart';
import '../modals/draw_with_result.dart';

class DrawResultService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static final Map<String, DrawWithResult> _cache = {};

  static void clearCache() {
    _cache.clear();
  }

  Future<DrawWithResult?> getDrawWithResults(String drawRunId) async {
    final doc = await _db.collection('drawRuns').doc(drawRunId).get();

    if (!doc.exists) {
      print("❌ drawRun not found: $drawRunId");
      return null;
    }

    final data = doc.data()!;

    final drawName = data['name'] ?? 'Draw';
    final settledAt = data['settledAt']?.toDate();

    final rawResult = data['settledResult'];

    final Map<String, dynamic> resultMap = rawResult is Map<String, dynamic>
        ? Map<String, dynamic>.from(rawResult)
        : {};

    final results =
        resultMap.entries
            .where((e) => e.key != 'drawnAt')
            .map((e) => DrawResult.fromDynamic(e.key, e.value))
            .toList()
          ..sort((a, b) => b.type.compareTo(a.type));

    return DrawWithResult(
      drawName: drawName,
      results: results,
      settledAt: settledAt,
    );
  }
}
