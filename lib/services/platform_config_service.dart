import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/modals/platform_config.dart';

class PlatformConfigService {
  static PlatformConfig? _config;
  final _db = FirebaseFirestore.instance;
  static Future<void> load() async {
    if (_config != null) return;

    final snap = await FirebaseFirestore.instance
        .collection("platformConfig")
        .doc("global")
        .get();

    if (!snap.exists) {
      throw Exception("PLATFORM_CONFIG_MISSING");
    }

    _config = PlatformConfig.fromMap(snap.data()!);
  }

  static PlatformConfig get current {
    if (_config == null) {
      throw Exception("PlatformConfig not loaded");
    }
    return _config!;
  }

  Stream<PlatformConfig> streamConfig() {
    return _db
        .collection('platformConfig')
        .doc('global') // 👈 must match backend
        .snapshots()
        .map((doc) {
          final data = doc.data();
          if (data == null) {
            throw Exception("Platform config not found");
          }
          return PlatformConfig.fromMap(data);
        });
  }

  /// Optional: one-time fetch (useful for guards)
  Future<PlatformConfig> fetchConfig() async {
    final doc = await _db.collection('platformConfig').doc('main').get();

    final data = doc.data();
    if (data == null) {
      throw Exception("Platform config not found");
    }

    return PlatformConfig.fromMap(data);
  }
}
