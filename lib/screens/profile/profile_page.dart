import 'package:flutter/material.dart';
import 'package:mobile_app/screens/app_shell.dart';
import 'package:mobile_app/screens/history/history_page.dart';
import 'package:mobile_app/screens/kyc/kyc_verification_page.dart';
import 'package:mobile_app/screens/profile/profile_settings_page.dart';
import 'package:mobile_app/screens/support/support_page.dart';
import 'package:mobile_app/screens/support/telegram_support_page.dart';
import '../wallet/wallet_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    Future<void> logout(BuildContext context) async {
      await FirebaseAuth.instance.signOut();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B0F2A), Color(0xFF1B0F4A), Color(0xFF2E1A7A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),

              // 👤 TITLE
              // const Text(
              //   "Profile",
              //   style: TextStyle(
              //     fontSize: 22,
              //     fontWeight: FontWeight.bold,
              //     color: Colors.cyanAccent,
              //   ),
              // ),
              const SizedBox(height: 20),

              // 👤 USER CARD
              _userCard(user),

              const SizedBox(height: 20),

              // 💰 WALLET PREVIEW
              _walletCard(),

              const SizedBox(height: 20),

              // ⚙️ OPTIONS
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _optionTile(
                      icon: Icons.receipt_long,
                      title: "My Tickets",
                      subtitle: "View all active tickets",
                      onTap: () {
                        MainLayout.of(context)?.setTab(1); // Tickets tab index
                      },
                    ),
                    _optionTile(
                      icon: Icons.history,
                      title: "History",
                      subtitle: "Past results & winnings",
                      onTap: () {
                        MainLayout.of(context)?.setTab(2); // History tab index
                      },
                    ),
                    _optionTile(
                      icon: Icons.account_balance_wallet,
                      title: "Wallet",
                      subtitle: "Add money & transactions",
                      onTap: () {
                        MainLayout.of(context)?.setTab(3); // Wallet tab index
                      },
                    ),
                    _optionTile(
                      icon: Icons.settings,
                      title: "Profile Settings",
                      subtitle: "Edit profile & username",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileSettingsPage(),
                          ),
                        );
                      },
                    ),

                    _optionTile(
                      icon: Icons.verified_user,
                      title: "KYC Verification",
                      subtitle: "Verify your account",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const KycVerificationPage(),
                          ),
                        );
                      },
                    ),

                    _optionTile(
                      icon: Icons.help_outline,
                      title: "Customer Support",
                      subtitle:
                          "Send a message & receive replies via notification",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SupportScreen(),
                          ),
                        );
                      },
                    ),

                    _optionTile(
                      icon: Icons.help_outline,
                      title: "Support Tickets",
                      subtitle: "Get help & contact us",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SupportPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 🚪 LOGOUT
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      final confirmed = await _confirmLogout(context);
                      if (!confirmed) return;

                      await FirebaseAuth.instance.signOut();

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    },

                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "LOGOUT",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmLogout(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1B0F4A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Confirm Logout",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "Are you sure you want to logout?",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Logout"),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _updateProfilePhoto(User user) async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75, // good balance
    );

    if (picked == null) return;

    final file = File(picked.path);

    // 🔑 IMPORTANT: do NOT hardcode .jpg
    // Let Storage + MIME type decide
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_photos')
        .child(user.uid)
        .child('avatar'); // no extension on purpose

    // Optional: set metadata (helps Storage & caching)
    final metadata = SettableMetadata(
      contentType: picked.mimeType, // image/png, image/webp, image/heic, etc
      cacheControl: 'public,max-age=86400',
    );

    await ref.putFile(file, metadata);

    final photoUrl = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'photoURL': photoUrl,
      'photoUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 👤 USER INFO CARD
  Widget _userCard(User user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;

        final username = data?['username'] ?? 'Set username';
        final phone = user.phoneNumber ?? 'No phone number';
        final photoUrl = data?['photoURL'];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF5A3DFF), Color(0xFF2B1B8F)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              // 👤 AVATAR (CLICKABLE)
              GestureDetector(
                onTap: () => _updateProfilePhoto(user),
                child: Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.3),
                        image: photoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(photoUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: photoUrl == null
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 32,
                            )
                          : null,
                    ),

                    // ✏️ EDIT ICON
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // USER DETAILS
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 💰 WALLET CARD
  Widget _walletCard() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final balance = (data?['walletBalance'] ?? 0).toDouble();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.black.withOpacity(0.35),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.cyanAccent,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Wallet Balance",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              Text(
                "₹${balance.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ⚙️ OPTION TILE
  Widget _optionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white24),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.cyanAccent),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.white54,
        ),
      ),
    );
  }
}
