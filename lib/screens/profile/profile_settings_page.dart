import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      return const Scaffold(
        body: Center(
          child: Text(
            "Please login again",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final uid = user.uid;

    if (!_loaded) {
      _loaded = true;
      _loadUser(uid);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F2A),
      appBar: AppBar(
        title: const Text(
          "Profile Settings",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: Colors.white, // 🔑 THIS IS THE FIX
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// USERNAME
            const Text("Username", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            TextField(
              controller: _usernameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "choose a username",
                hintStyle: const TextStyle(color: Colors.white38),
                errorText: _usernameError,
                suffixIcon: _checkingUsername
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _usernameAvailable
                    ? const Icon(Icons.check, color: Colors.greenAccent)
                    : null,
              ),
              onChanged: (v) => _checkUsername(v.trim(), uid),
            ),

            const SizedBox(height: 20),

            /// DISPLAY NAME
            const Text("Your Name", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            TextField(
              controller: _displayNameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Enter your name",
                hintStyle: TextStyle(color: Colors.white38),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 20),

            /// READ ONLY
            // _readonlyField("Email", user.email ?? "—"),
            // const SizedBox(height: 16),
            _readonlyField("Phone", user.phoneNumber ?? "—"),
            const SizedBox(height: 16),
            _readonlyField("KYC Status", _kycStatus),

            const SizedBox(height: 28),

            /// SAVE
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (_hasChanges && _usernameAvailable && !_checkingUsername)
                    ? () => _save(uid)
                    : null,
                child: const Text("SAVE CHANGES"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
