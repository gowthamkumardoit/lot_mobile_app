import 'package:cloud_firestore/cloud_firestore.dart';

class DrawRun {
  final String id;
  final String drawId;
  final String? drawName;
  final String date; // YYYY-MM-DD
  final String? drawTimeStr; // HH:mm

  final bool enable2D;
  final bool enable3D;
  final bool enable4D;
  final int multiplier2D;
  final int multiplier3D;
  final int multiplier4D;

  final Timestamp? lockedAt;
  final Timestamp? drawnAt;

  DrawRun({
    required this.id,
    required this.drawId,
    this.drawName,
    this.drawTimeStr,
    required this.date,
    required this.enable2D,
    required this.enable3D,
    required this.enable4D,
    required this.multiplier2D,
    required this.multiplier3D,
    required this.multiplier4D,
    this.lockedAt,
    this.drawnAt,
  });

  // ---------- STATUS ----------
  bool get isLocked => lockedAt != null && drawnAt == null;
  bool get isCompleted => drawnAt != null;
  bool get isOpen => lockedAt == null && drawnAt == null;

  // ---------- UI ----------
  String get title => drawName ?? drawId;

  /// Returns HH:mm
  String get drawTime {
    if (drawTimeStr != null && drawTimeStr!.isNotEmpty) {
      return drawTimeStr!;
    }
    return '--:--';
  }

  /// 🔥 Reliable DateTime using DATE + TIME (not DateTime.now)
  DateTime? get drawDateTime {
    if (drawTime == '--:--' || date.isEmpty) return null;

    try {
      final dateParts = date.split('-');
      final timeParts = drawTime.split(':');

      if (dateParts.length != 3 || timeParts.length != 2) return null;

      return DateTime(
        int.parse(dateParts[0]), // year
        int.parse(dateParts[1]), // month
        int.parse(dateParts[2]), // day
        int.parse(timeParts[0]), // hour
        int.parse(timeParts[1]), // minute
      );
    } catch (_) {
      return null;
    }
  }

  // ---------- REALTIME STREAM ----------
  /// Used to auto-redirect when draw locks / completes
  Stream<DrawRun> stream() {
    return FirebaseFirestore.instance
        .collection('drawRuns')
        .doc(id)
        .snapshots()
        .where((doc) => doc.exists)
        .map((doc) => DrawRun.fromDoc(doc));
  }

  // ---------- FIRESTORE ----------
  factory DrawRun.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final config = data['configSnapshot'] as Map<String, dynamic>? ?? {};

    return DrawRun(
      id: doc.id,
      drawId: data['drawId'] ?? '',
      drawName: data['name'],
      drawTimeStr: data['time'], // must be HH:mm
      date: data['date'] ?? '',

      enable2D: config['enable2D'] ?? false,
      enable3D: config['enable3D'] ?? false,
      enable4D: config['enable4D'] ?? false,

      multiplier2D: config['multiplier2D'] ?? 0,
      multiplier3D: config['multiplier3D'] ?? 0,
      multiplier4D: config['multiplier4D'] ?? 0,

      lockedAt: data['lockedAt'] is Timestamp ? data['lockedAt'] : null,
      drawnAt: data['drawnAt'] is Timestamp ? data['drawnAt'] : null,
    );
  }
}
