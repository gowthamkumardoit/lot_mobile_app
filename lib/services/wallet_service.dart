import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/modals/wallet_modal.dart';
import 'package:mobile_app/modals/withdraw_request.dart';
import '../modals/wallet_txn.dart';
import '../modals/topup_request.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class WalletService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// 💰 WALLET BALANCE (AUTHORITATIVE, FAST)
  /// Comes from users.walletBalance
  Stream<int> getBalance(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return 0;
      final data = doc.data();
      if (data == null) return 0;
      return (data['walletBalance'] ?? 0) as int;
    });
  }

  static Future<void> createWithdrawAmountRequest({required int amount}) async {
    final functions = FirebaseFunctions.instanceFor(region: 'asia-south1');

    final callable = functions.httpsCallable('submitWithdraw');
    debugPrint('🔥 FUNCTIONS ERROR');
    try {
      await callable.call({'amount': amount});
    } on FirebaseFunctionsException catch (e) {
      // 🔍 FULL DEBUG OUTPUT
      debugPrint('🔥 FUNCTIONS ERROR');
      debugPrint('code   : ${e.code}');
      debugPrint('message: ${e.message}');
      debugPrint('details: ${e.details}');

      // Re-throw clean message for UI
      throw Exception(e.message ?? 'Withdrawal failed (${e.code})');
    } catch (e, st) {
      // 🔥 Non-functions error
      debugPrint('🔥 UNKNOWN ERROR: $e');
      debugPrint('STACKTRACE: $st');
      rethrow;
    }
  }

  /// 📜 WALLET TRANSACTION HISTORY (LEDGER)
  /// Immutable audit log
  Stream<List<WalletTxn>> getWalletTxns(String userId) {
    return _db
        .collection('walletTxns')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(15)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((d) {
                try {
                  return WalletTxn.fromDoc(d);
                } catch (_) {
                  return null;
                }
              })
              .whereType<WalletTxn>()
              // ✅ HIDE pending withdrawal locks from Recent Activity
              .where((txn) => txn.type != "LOCK")
              .toList();
        });
  }

  Stream<List<WalletTxn>> getAllWalletTxns(String userId) {
    return _db
        .collection('walletTxns')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((d) {
                try {
                  return WalletTxn.fromDoc(d);
                } catch (_) {
                  return null;
                }
              })
              .whereType<WalletTxn>()
              .toList();
        });
  }

  /// 🕓 PENDING TOP-UP REQUESTS (INTENT ONLY)
  Stream<List<TopupRequest>> getPendingTopups(String userId) {
    return _db
        .collection('topupRequests')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'SUBMITTED')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((d) {
                try {
                  return TopupRequest.fromDoc(d);
                } catch (_) {
                  return null;
                }
              })
              .whereType<TopupRequest>()
              .toList();
        });
  }

  // ─────────────────────────────────────────────
  // 🚫 IMPORTANT SECURITY NOTE
  // ─────────────────────────────────────────────
  //
  // ❌ DO NOT add credit() or debit() methods here
  // ❌ Wallet mutations must ONLY happen via:
  //
  //   • approveTopup (Cloud Function)
  //   • purchase2DTicket / purchase3DTicket (CF)
  //   • winningSettlement (CF)
  //
  // This guarantees:
  // ✅ No client fraud
  // ✅ Atomic ledger + balance
  // ✅ Auditable money flow
  //
  // ─────────────────────────────────────────────

  /// 🏦 Submit bank / UPI for approval
  static Future<void> submitBankAccount(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not authenticated");

    await _db.collection('users').doc(user.uid).collection('bankAccounts').add({
      ...data,
      "status": "PENDING", // PENDING | APPROVED | REJECTED
      "createdAt": FieldValue.serverTimestamp(),
      "approvedAt": null,
      "rejectedReason": null,
    });
  }

  /// ✅ Get approved bank account (returns ID or null)
  static Future<String?> getApprovedBankAccountId() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snap = await _db
        .collection('users')
        .doc(user.uid)
        .collection('bankAccounts')
        .where('status', isEqualTo: 'APPROVED')
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  static Stream<String?> bankApprovalStatus() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('bankAccounts')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          return snap.docs.first['status'] as String;
        });
  }

  static Future<Map<String, dynamic>?> getLatestUpiAccounts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _db.collection('upiWithdrawals').doc(uid).get();

    if (!doc.exists) return null;

    final data = doc.data()!;

    return {
      "status": (data["status"] as String?)?.toUpperCase() ?? "PENDING",
      "primaryUpi": data["primaryUpi"],
      "secondaryUpi": data["secondaryUpi"],
    };
  }

  /// 💸 Create withdraw request (INTENT ONLY)
  static Future<void> createWithdrawRequest({required int amount}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("NOT_AUTHENTICATED");
    }

    // 🔑 Fetch approved UPI
    final upiDoc = await _db.collection('upiWithdrawals').doc(user.uid).get();

    if (!upiDoc.exists) {
      throw Exception("UPI_NOT_SUBMITTED");
    }

    final upiData = upiDoc.data()!;
    final status = (upiData['status'] as String?)?.toUpperCase();

    if (status != "APPROVED") {
      throw Exception("UPI_NOT_APPROVED");
    }

    final primaryUpi = upiData['primaryUpi'];
    final secondaryUpi = upiData['secondaryUpi'];

    if (primaryUpi == null || primaryUpi.toString().isEmpty) {
      throw Exception("PRIMARY_UPI_MISSING");
    }

    // 🔒 Create withdraw request
    await _db.collection('withdrawalRequests').add({
      "userId": user.uid,
      "amount": amount,

      // ✅ UPI DETAILS (snapshot at time of request)
      "primaryUpi": primaryUpi,
      "secondaryUpi": secondaryUpi,

      // 🔄 STATUS
      "status": "PENDING", // Admin controlled
      // 🕒 AUDIT
      "createdAt": FieldValue.serverTimestamp(),
      "processedAt": null,
    });
  }

  static Future<int> getWalletBalance() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;

    final snap = await _db.collection('users').doc(uid).get();

    if (!snap.exists) return 0;

    final data = snap.data();
    return (data?['walletBalance'] ?? 0) as int;
  }

  static Future<void> submitUpiAccounts(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("NOT_AUTHENTICATED");
    }

    final fs = FirebaseFirestore.instance;

    final docRef = fs.collection("upiWithdrawals").doc(user.uid);

    final payload = {
      "userId": user.uid,
      "primaryUpi": data["primaryUpi"],
      "secondaryUpi": data["secondaryUpi"],
      "status": "PENDING", // PENDING | APPROVED | REJECTED
      "submittedAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    };

    await fs.runTransaction((tx) async {
      final snap = await tx.get(docRef);

      if (snap.exists) {
        // Update existing (re-submit flow)
        tx.update(docRef, payload);
      } else {
        // First-time submit
        tx.set(docRef, payload);
      }
    });
  }

  static Future<void> deleteUpiAccounts() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("upi_accounts")
        .doc("latest")
        .delete();
  }

  Stream<WithdrawRequest?> getPendingWithdrawal(String userId) {
    return FirebaseFirestore.instance
        .collection('withdrawalRequests')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['SUBMITTED', 'PROCESSING'])
        .limit(1)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          return WithdrawRequest.fromDoc(snap.docs.first);
        });
  }

  Stream<WalletBalance> getWalletBalances(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return WalletBalance(
              wallet: 0,
              locked: 0,
              bonus: 0,
              bonusExpiry: null,
            );
          }

          final data = doc.data()!;

          return WalletBalance(
            wallet: data['walletBalance'] ?? 0,
            locked: data['lockedBalance'] ?? 0,
            bonus: data['bonusBalance'] ?? 0,
            bonusExpiry: (data['bonusExpiry'] as Timestamp?)?.toDate(),
          );
        });
  }
}
