import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/screens/wallet/wallet_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

const walletBg = Color(0xFF0B1220);
const walletSurface = Color(0xFF11172C);
const walletCardDark = Color(0xFF141B34);
const walletAccent = Color(0xFF3B6CFF);
const walletAccent2 = Color(0xFF00E5FF);
const walletCredit = Color(0xFF2EFF7A);
const walletDebit = Color(0xFFFF5C5C);

class TopUpBottomSheet extends StatefulWidget {
  const TopUpBottomSheet({super.key});

  @override
  State<TopUpBottomSheet> createState() => _TopUpBottomSheetState();
}

class _TopUpBottomSheetState extends State<TopUpBottomSheet> {
  final amountCtrl = TextEditingController();
  final utrCtrl = TextEditingController();

  File? proofImage;
  bool uploading = false;

  String mode = "UPI"; // always visible

  // ---------------- UPI OPEN ----------------

  Future<void> _openUpiApp({
    required String upiId,
    required String name,
  }) async {
    final amount = int.tryParse(amountCtrl.text);
    if (amount == null || amount < 50) {
      _showError("Minimum top-up is ₹50");
      return;
    }

    final note =
        "TOPUP_${FirebaseAuth.instance.currentUser!.uid.substring(0, 6)}";

    final uri = Uri.parse(
      "upi://pay"
      "?pa=$upiId"
      "&pn=${Uri.encodeComponent(name)}"
      "&am=$amount"
      "&cu=INR"
      "&tn=$note",
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showError("No UPI app found");
    }
  }

  void _copyUpi(String upiId) {
    Clipboard.setData(ClipboardData(text: upiId));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("UPI ID copied")));
  }

  // ---------------- IMAGE PICK ----------------

  Future<void> _pickProofImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);
    final sizeMb = await file.length() / (1024 * 1024);
    if (sizeMb > 5) {
      _showError("Image too large (max 5MB)");
      return;
    }

    setState(() => proofImage = file);
  }

  // ---------------- IMAGE UPLOAD ----------------

  Future<String?> _uploadProof(String userId) async {
    if (proofImage == null) return null;

    try {
      setState(() => uploading = true);
      final ext = path.extension(proofImage!.path);
      final ref = FirebaseStorage.instance.ref(
        'topup_proofs/$userId/${DateTime.now().millisecondsSinceEpoch}$ext',
      );
      await ref.putFile(proofImage!);
      return await ref.getDownloadURL();
    } catch (_) {
      _showError("Upload failed");
      return null;
    } finally {
      setState(() => uploading = false);
    }
  }

  // ---------------- SUBMIT ----------------

  Future<void> _submit() async {
    if (uploading) return;

    final amount = int.tryParse(amountCtrl.text);
    if (amount == null || amount < 50) {
      _showError("Minimum top-up is ₹50");
      return;
    }

    if (proofImage == null) {
      _showError("Upload payment proof");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final proofUrl = await _uploadProof(user.uid);
    if (proofUrl == null) return;

    await FirebaseFirestore.instance.collection("topupRequests").add({
      "userId": user.uid,
      "amount": amount,
      "utr": utrCtrl.text.isEmpty ? null : utrCtrl.text.toUpperCase(),
      "proofUrl": proofUrl,
      "mode": mode,
      "status": "SUBMITTED",
      "createdAt": FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.pop(context);
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        decoration: const BoxDecoration(
          color: walletSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dragHandle(),
              const Text(
                "Top Up Wallet",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 16),

              /// AMOUNT (PRIMARY)
              _input(amountCtrl, "Amount", "Minimum ₹50", TextInputType.number),
              const SizedBox(height: 16),

              /// PAYMENT METHOD
              const Text(
                "Payment Method",
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _modeSelector(),

              const SizedBox(height: 16),
              _paymentDetails(),

              const SizedBox(height: 16),
              _input(utrCtrl, "UTR (optional)", "Enter reference if any"),

              const SizedBox(height: 14),
              _uploadProofWidget(),

              const SizedBox(height: 20),
              _submitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentDetails() {
    if (mode != "UPI") return const SizedBox();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("settings")
          .doc("payouts")
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();

        final data = snap.data!.data() as Map<String, dynamic>?;
        final List upis = (data?['upiAccounts'] ?? [])
            .where((e) => e['enabled'] == true)
            .toList();

        return Column(
          children: upis.map((u) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (u['qr'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        u['qr'],
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                u['upiId'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.copy,
                                size: 18,
                                color: Colors.white70,
                              ),
                              onPressed: () => _copyUpi(u['upiId']),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _openUpiApp(
                              upiId: u['upiId'],
                              name: "Lottery Wallet",
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: walletAccent,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text("Pay via UPI"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _modeSelector() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("settings")
          .doc("payouts")
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final bankEnabled = data?['bank']?['enabled'] == true;

        return Row(
          children: [
            _pill("UPI"),
            if (bankEnabled) ...[const SizedBox(width: 10), _pill("BANK")],
          ],
        );
      },
    );
  }

  Widget _pill(String value) {
    final active = mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => mode = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? walletAccent : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                color: active ? Colors.black : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController c,
    String l,
    String h, [
    TextInputType k = TextInputType.text,
  ]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          keyboardType: k,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: h,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _uploadProofWidget() => InkWell(
    onTap: uploading ? null : _pickProofImage,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(
            proofImage != null ? Icons.check : Icons.upload,
            color: walletAccent ,
          ),
          const SizedBox(width: 10),
          Text(
            proofImage != null
                ? "Payment proof selected"
                : "Upload payment proof",
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    ),
  );

  Widget _submitButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: uploading ? null : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: walletAccent ,
        padding: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: uploading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text("Submit Top-Up Request"),
    ),
  );

  Widget _dragHandle() => Center(
    child: Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
