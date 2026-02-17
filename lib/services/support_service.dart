import 'package:cloud_functions/cloud_functions.dart';

class SupportService {
  static Future<void> sendMessage(String message) async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      "sendSupportMessage",
    );

    await callable.call({"message": message});
  }
}
