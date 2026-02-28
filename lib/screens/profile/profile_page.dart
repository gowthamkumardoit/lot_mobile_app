import 'package:flutter/material.dart';
import 'package:mobile_app/screens/app_shell.dart';
import 'package:mobile_app/screens/kyc/kyc_verification_page.dart';
import 'package:mobile_app/screens/profile/profile_settings_page.dart';
import 'package:mobile_app/screens/support/support_page.dart';
import 'package:mobile_app/screens/support/telegram_support_page.dart';
import 'package:mobile_app/widgets/lottery_rules_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'bank_accounts_page.dart';

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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Android
        statusBarBrightness: Brightness.light, // iOS
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              _header(),
              const SizedBox(height: 24),
              _userCard(user),
              const SizedBox(height: 24),

              /// 👇 Only ONE Expanded
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView(
                    children: [
                      _optionTile(
                        icon: Icons.receipt_long,
                        title: "My Tickets",
                        subtitle: "View all active tickets",
                        onTap: () {
                          MainLayout.of(context)?.setTab(1);
                        },
                      ),
                      _optionTile(
                        icon: Icons.history,
                        title: "History",
                        subtitle: "Past results & winnings",
                        onTap: () {
                          MainLayout.of(context)?.setTab(2);
                        },
                      ),
                      _optionTile(
                        icon: Icons.account_balance_wallet,
                        title: "Wallet",
                        subtitle: "Add money & transactions",
                        onTap: () {
                          MainLayout.of(context)?.setTab(3);
                        },
                      ),
                      _optionTile(
                        icon: Icons.account_balance,
                        title: "Bank Accounts",
                        subtitle: "Add or manage withdrawal bank accounts",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BankAccountsPage(),
                            ),
                          );
                        },
                      ),
                      _optionTile(
                        icon: Icons.verified_user,
                        title: "KYC Verification",
                        subtitle:
                            "Complete your identity verification to enable withdrawals",
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
                        icon: Icons.rule,
                        title: "Lottery Rules",
                        subtitle: "Read app rules & policies",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LotteryRulesScreen(),
                            ),
                          );
                        },
                      ),
                      _optionTile(
                        icon: Icons.support_agent,
                        title: "Customer Support",
                        subtitle: "Send a message & receive replies",
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
                        icon: Icons.help_center,
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

                      const SizedBox(height: 30),

                      /// 👇 Logout inside same scroll
                      _logoutButton(context),

                      const SizedBox(height: 100), // space for bottom nav
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "Profile",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E1E1E),
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
          margin: const EdgeInsets.symmetric(horizontal: 14),
          padding: const EdgeInsets.all(14),
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

  // ⚙️ OPTION TILE
  Widget _optionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10), // ↓ reduced spacing
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14), // slightly smaller
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        dense: true, // 🔥 reduces tile height
        visualDensity: const VisualDensity(vertical: 0), // extra compact
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(6), // smaller icon padding
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF4B5563),
            size: 16, // ↓ smaller icon
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13, // ↓ smaller title
            color: Color(0xFF111827),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 11, // ↓ smaller subtitle
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14, // ↓ smaller arrow
          color: Color(0xFF9CA3AF),
        ),
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final confirmed = await _confirmLogout(context);
          if (!confirmed) return;

          await FirebaseAuth.instance.signOut();

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF5F6D), Color(0xFFFF3D54)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                "Logout",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
