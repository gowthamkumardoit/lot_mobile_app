import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/screens/app_shell.dart';
import 'package:mobile_app/screens/auth/login_screen.dart';

import '../home/home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        // 🔄 Auth still loading
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ Not logged in
        final user = authSnap.data;
        if (user == null) {
          return const LoginScreen(); // OTP login page
        }

        // ✅ Logged in → check profile
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // 🆕 New user → username setup
            if (!userSnap.hasData || !userSnap.data!.exists) {
              return const MainLayout();
            }

            // 🎯 Existing user
            return const MainLayout();
          },
        );
      },
    );
  }
}
