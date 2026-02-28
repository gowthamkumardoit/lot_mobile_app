import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class KycVerificationPage extends StatefulWidget {
  const KycVerificationPage({super.key});

  @override
  State<KycVerificationPage> createState() => _KycVerificationPageState();
}

class _KycVerificationPageState extends State<KycVerificationPage> {
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _docNumberCtrl = TextEditingController();

  String _docType = "AADHAAR";
  File? _image;
  bool _submitting = false;

  String _kycStatus = "NOT_SUBMITTED";
  bool _loadingStatus = true;

  final picker = ImagePicker();

  final _aadhaarRegex = RegExp(r'^[0-9]{12}$');
  final _panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
  final _dobRegex = RegExp(r'^\d{2}-\d{2}-\d{4}$');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _docNumberCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadKycStatus();
  }

  bool get _dobValid {
    final value = _dobCtrl.text.trim();

    // Format check
    if (!_dobRegex.hasMatch(value)) return false;

    try {
      final parts = value.split("-");
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final dob = DateTime(year, month, day);

      // Invalid calendar date (like 31-02-2020)
      if (dob.day != day || dob.month != month || dob.year != year) {
        return false;
      }

      final now = DateTime.now();

      // Future date check
      if (dob.isAfter(now)) return false;

      // Age check (18+)
      final age =
          now.year -
          dob.year -
          ((now.month < dob.month ||
                  (now.month == dob.month && now.day < dob.day))
              ? 1
              : 0);

      if (age < 18) return false;

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadKycStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final kycReqSnap = await FirebaseFirestore.instance
        .collection("kycRequests")
        .doc(user.uid)
        .get();

    if (kycReqSnap.exists) {
      setState(() {
        _kycStatus = kycReqSnap.data()?['status'] ?? "SUBMITTED";
        _loadingStatus = false;
      });
      return;
    }

    // fallback (first time users)
    final userSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    setState(() {
      _kycStatus = userSnap.data()?['kycStatus'] ?? "NOT_SUBMITTED";
      _loadingStatus = false;
    });
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  bool get _docValid {
    final v = _docNumberCtrl.text.trim();
    if (_docType == "AADHAAR") return _aadhaarRegex.hasMatch(v);
    return _panRegex.hasMatch(v);
  }

  Future<void> _submitKyc() async {
    final ext = path.extension(_image!.path); // .jpg / .png / .heic etc
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _image == null) return;

    setState(() => _submitting = true);

    try {
      final ref = FirebaseStorage.instance.ref(
        "kyc_docs/${user.uid}/document_${DateTime.now().millisecondsSinceEpoch}$ext",
      );

      await ref.putFile(
        _image!,
        SettableMetadata(contentType: "image/${ext.replaceFirst('.', '')}"),
      );

      final imageUrl = await ref.getDownloadURL();

      final batch = FirebaseFirestore.instance.batch();

      batch.set(
        FirebaseFirestore.instance.collection("kycRequests").doc(user.uid),
        {
          "uid": user.uid,
          "fullName": _nameCtrl.text.trim(),
          "dob": _dobCtrl.text.trim(),
          "docType": _docType,
          "docNumber": _docNumberCtrl.text.trim(),
          "docImageUrl": imageUrl,
          "status": "SUBMITTED",
          "createdAt": FieldValue.serverTimestamp(),
        },
      );

      batch.update(
        FirebaseFirestore.instance.collection("users").doc(user.uid),
        {
          "kycStatus": "SUBMITTED",
          "kycSubmittedAt": FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("KYC upload failed: $e");

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("KYC upload failed")));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _kycForm() {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("KYC Verification")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Complete your identity verification",
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),

            _field("Full Name", _nameCtrl),
            _field(
              "Date of Birth (DD-MM-YYYY)",
              _dobCtrl,
              error: _dobCtrl.text.isEmpty || _dobValid
                  ? null
                  : "Enter valid DOB (18+ required)",
            ),

            Text("Document Type", style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _docType,
              decoration: const InputDecoration(),
              items: const [
                DropdownMenuItem(value: "AADHAAR", child: Text("Aadhaar Card")),
                DropdownMenuItem(value: "PAN", child: Text("PAN Card")),
              ],
              onChanged: (v) {
                setState(() {
                  _docType = v!;
                  _docNumberCtrl.clear();
                });
              },
            ),

            const SizedBox(height: 16),

            _field(
              _docType == "AADHAAR"
                  ? "Aadhaar Number (12 digits)"
                  : "PAN Number (ABCDE1234F)",
              _docNumberCtrl,
              error: _docNumberCtrl.text.isEmpty || _docValid
                  ? null
                  : "Invalid ${_docType} number",
            ),

            const SizedBox(height: 24),

            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                  ),
                  color: Colors.white,
                ),
                child: _image == null
                    ? Center(
                        child: Text(
                          "Tap to upload document image",
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      ),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_submitting || !_docValid || !_dobValid || _image == null)
                    ? null
                    : _submitKyc,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("SUBMIT KYC"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingStatus) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    switch (_kycStatus) {
      case "SUBMITTED":
        return _statusScreen(
          title: "KYC Submitted",
          message:
              "Your KYC documents are under review.\nThis usually takes 24–48 hours.",
          icon: Icons.hourglass_top,
          color: Colors.orangeAccent,
        );

      case "APPROVED":
        return _statusScreen(
          title: "KYC Verified",
          message: "Your identity has been successfully verified.",
          icon: Icons.verified,
          color: Colors.greenAccent,
        );

      case "REJECTED":
        return _statusScreen(
          title: "KYC Rejected",
          message:
              "Your documents were rejected.\nPlease submit clear and valid details.",
          icon: Icons.error_outline,
          color: Colors.redAccent,
          action: ElevatedButton(
            onPressed: () {
              setState(() => _kycStatus = "NOT_SUBMITTED");
            },
            child: const Text("RE-SUBMIT KYC"),
          ),
        );

      default:
        return _kycForm(); // NOT_SUBMITTED ONLY
    }
  }

  Widget _field(String label, TextEditingController ctrl, {String? error}) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(errorText: error),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  InputDecoration _inputDecoration({String? errorText}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      errorText: errorText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.cyanAccent),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}

Widget _statusScreen({
  required String title,
  required String message,
  required IconData icon,
  required Color color,
  Widget? action,
}) {
  return Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(
      title: const Text("KYC Verification"),
      backgroundColor: Colors.transparent,
      leading: const BackButton(color: Colors.white),
      elevation: 0,
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 80, color: color),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            if (action != null) ...[const SizedBox(height: 24), action],
          ],
        ),
      ),
    ),
  );
}
