import 'package:cloud_functions/cloud_functions.dart';

class TicketService {
  final _functions = FirebaseFunctions.instanceFor(region: 'asia-south1');

  /// 🔐 SAFE: wallet + ledger + tickets (2D)
  Future<void> purchase2DTicket({
    required String drawId,
    required Map<String, int> numbers,
  }) async {
    try {
      await _functions.httpsCallable('purchase2DTicket').call({
        'drawId': drawId,
        'numbers': numbers,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Unable to place ticket');
    }
  }

  /// 🔐 SAFE: wallet + ledger + tickets (3D)
  Future<void> purchase3DTicket({
    required String drawId,
    required Map<String, int> numbers,
  }) async {
    try {
      await _functions.httpsCallable('purchase3DTicket').call({
        'drawId': drawId,
        'numbers': numbers,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Unable to place ticket');
    }
  }

  Future<void> purchase4DTicket({
    required String drawId,
    required Map<String, int> numbers,
  }) async {
    try {
      await _functions.httpsCallable('purchase4DTicket').call({
        'drawId': drawId,
        'numbers': numbers,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Unable to place ticket');
    }
  }
}
