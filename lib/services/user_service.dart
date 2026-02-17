import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  /// Stream user KYC approval state
  Stream<bool> streamKycApproved(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return false;

      // Adjust field if your backend uses a different name
      return data['kycStatus'] == "APPROVED";
    });
  }

  /// Optional one-time fetch
  Future<bool> fetchKycApproved(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['kycStatus'] == "APPROVED";
  }
}
