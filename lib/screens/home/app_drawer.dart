import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/screens/app_shell.dart';
import 'package:mobile_app/screens/support/how_to_play_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<String?> _getAvatarUrl(String uid) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'profile_photos/$uid/avatar',
      );
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Drawer(child: SizedBox());
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            /// HEADER
            FutureBuilder<String?>(
              future: _getAvatarUrl(user.uid),
              builder: (context, snapshot) {
                final avatar = snapshot.data;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6A3D), Color(0xFFFF8A00)],
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        backgroundImage: avatar != null
                            ? NetworkImage(avatar)
                            : const AssetImage("assets/images/avatar.png")
                                  as ImageProvider,
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Kuber Player",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.phoneNumber ?? "",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            /// MENU
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerItem(
                    icon: Icons.home,
                    title: "Home",
                    onTap: () {
                      Navigator.pop(context);
                      MainLayout.of(context)?.setTab(0);
                    },
                  ),

                  _drawerItem(
                    icon: Icons.account_balance_wallet,
                    title: "Wallet",
                    onTap: () {
                      Navigator.pop(context);
                      MainLayout.of(context)?.setTab(3);
                    },
                  ),

                  _drawerItem(
                    icon: Icons.confirmation_num,
                    title: "My Tickets",
                    onTap: () {
                      Navigator.pop(context);
                      MainLayout.of(context)?.setTab(1);
                    },
                  ),

                  _drawerItem(
                    icon: Icons.emoji_events,
                    title: "History",
                    onTap: () {
                      Navigator.pop(context);
                      MainLayout.of(context)?.setTab(2);
                    },
                  ),

                  const Divider(height: 32),

                  _drawerItem(
                    icon: Icons.help_outline,
                    title: "How To Play",
                    onTap: () {
                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HowToPlayPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            /// LOGOUT (Always visible)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
