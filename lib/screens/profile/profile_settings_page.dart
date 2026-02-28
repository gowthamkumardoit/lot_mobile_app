import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _usernameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();

  final _usernameRegex = RegExp(r'^[a-z0-9_]{4,20}$');

  bool _checkingUsername = false;
  bool _usernameAvailable = false;
  String? _usernameError;

  bool _loaded = false;

  String _initialUsername = "";
  String _initialDisplayName = "";
  String _kycStatus = "PENDING";

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _displayNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = snap.data();
    if (data == null) return;

    _initialUsername = data['username'] ?? '';
    _initialDisplayName = data['displayName'] ?? '';
    _kycStatus = data['kycStatus'] ?? 'PENDING';

    _usernameCtrl.text = _initialUsername;
    _displayNameCtrl.text = _initialDisplayName;

    _usernameAvailable = _initialUsername.isNotEmpty;

    if (mounted) setState(() {});
  }

  bool get _hasChanges {
    return _usernameCtrl.text.trim() != _initialUsername ||
        _displayNameCtrl.text.trim() != _initialDisplayName;
  }

  Future<void> _checkUsername(String value, String uid) async {
    setState(() {
      _checkingUsername = true;
      _usernameError = null;
      _usernameAvailable = false;
    });

    if (!_usernameRegex.hasMatch(value)) {
      setState(() {
        _checkingUsername = false;
        _usernameError =
            "4–20 chars, lowercase letters, numbers & underscore only";
      });
      return;
    }

    final ref = FirebaseFirestore.instance.collection('usernames').doc(value);
    final snap = await ref.get();

    setState(() {
      _checkingUsername = false;
      _usernameAvailable = !snap.exists || snap.data()?['uid'] == uid;
      if (!_usernameAvailable) {
        _usernameError = "Username already taken";
      }
    });
  }

  Future<void> _save(String uid) async {
    if (!_hasChanges || !_usernameAvailable || _checkingUsername) return;

    final username = _usernameCtrl.text.trim();
    final displayName = _displayNameCtrl.text.trim();

    final batch = FirebaseFirestore.instance.batch();

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final usernameRef = FirebaseFirestore.instance
        .collection('usernames')
        .doc(username);

    batch.set(usernameRef, {"uid": uid});
    batch.update(userRef, {
      "username": username,
      "displayName": displayName,
      "updatedAt": FieldValue.serverTimestamp(),
    });

    await batch.commit();

    if (mounted) Navigator.pop(context);
  }

  Widget _readonlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(value, style: const TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login again")));
    }

    final uid = user.uid;

    if (!_loaded) {
      _loaded = true;
      _loadUser(uid);
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Android
        statusBarBrightness: Brightness.light, // iOS
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          title: const Text(
            "Profile Settings",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black87,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Username",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _modernTextField(
                      controller: _usernameCtrl,
                      hint: "choose a username",
                      error: _usernameError,
                      suffix: _checkingUsername
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : _usernameAvailable
                          ? const Icon(
                              Icons.check,
                              color: Colors.green,
                              size: 20,
                            )
                          : null,
                      onChanged: (v) => _checkUsername(v.trim(), uid),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Your Name",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _modernTextField(
                      controller: _displayNameCtrl,
                      hint: "Enter your name",
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _sectionCard(
                child: Column(
                  children: [
                    _infoRow("Phone", user.phoneNumber ?? "—"),
                    const Divider(height: 24),
                    _infoRow(
                      "KYC Status",
                      _kycStatus,
                      valueColor: _kycStatus == "APPROVED"
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (_hasChanges && _usernameAvailable && !_checkingUsername)
                      ? () => _save(uid)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "SAVE CHANGES",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _sectionCard({required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

Widget _modernTextField({
  required TextEditingController controller,
  required String hint,
  String? error,
  Widget? suffix,
  ValueChanged<String>? onChanged,
}) {
  return TextField(
    controller: controller,
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint,
      errorText: error,
      filled: true,
      fillColor: const Color(0xFFF1F3F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      suffixIcon: suffix,
    ),
  );
}

Widget _infoRow(String label, String value, {Color? valueColor}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
      Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: valueColor ?? Colors.black87,
        ),
      ),
    ],
  );
}
