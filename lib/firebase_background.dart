import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ⚠️ MUST be the ONLY thing here
  await Firebase.initializeApp();

  // ❌ DO NOT:
  // - show local notifications
  // - access Firestore
  // - access Auth
  // - use BuildContext
}
