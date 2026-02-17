import 'draw_result.dart';

class DrawWithResult {
  final String drawName;
  final List<DrawResult> results;
  final DateTime? settledAt; // ✅ ADD THIS

  DrawWithResult({
    required this.drawName,
    required this.results,
    this.settledAt, // ✅ ADD THIS
  });
}
