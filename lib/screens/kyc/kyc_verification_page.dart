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
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F2A),
      appBar: AppBar(
        title: const Text(
          "KYC Verification",
          style: TextStyle(color: Colors.white),
        ),
        leading: const BackButton(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field("Full Name", _nameCtrl),
            _field("Date of Birth (YYYY-MM-DD)", _dobCtrl),

            const Text(
              "Document Type",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 6),

            DropdownButtonFormField<String>(
              value: _docType,
              dropdownColor: const Color(0xFF151A3A),
              style: const TextStyle(color: Colors.white),
              iconEnabledColor: Colors.cyanAccent,
              decoration: _inputDecoration(),
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

            const SizedBox(height: 20),

            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.cyanAccent),
                  color: Colors.white.withOpacity(0.05),
                ),
                child: _image == null
                    ? const Center(
                        child: Text(
                          "Tap to upload document image",
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      ),
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_submitting || !_docValid || _image == null)
                    ? null
                    : _submitKyc,
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
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
        backgroundColor: Color(0xFF0B0F2A),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration(errorText: error),
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
    backgroundColor: const Color(0xFF0B0F2A),
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
