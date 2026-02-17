import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/screens/app_shell.dart';

import 'otp_screen.dart';
import 'dart:ui';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  bool loading = false;

  Future<void> sendOtp() async {
    final phone = phoneController.text.trim();

    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid 10 digit number')),
      );
      return;
    }

    setState(() => loading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91$phone',
      verificationCompleted: (PhoneAuthCredential credential) async {
        // 🔥 AUTO-READ OTP SUCCESS
        await FirebaseAuth.instance.signInWithCredential(credential);

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainLayout()),
          (_) => false,
        );
      },

      verificationFailed: (FirebaseAuthException e) {
        setState(() => loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message ?? 'OTP failed')));
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() => loading = false);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(verificationId: verificationId),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🌌 BACKGROUND GRADIENT
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0B0F2A),
                  Color(0xFF1B0F4A),
                  Color(0xFF2E026D),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          /// ✨ GLOW BLOBS
          Positioned(
            top: -120,
            right: -100,
            child: _glowBlob(260, Colors.purpleAccent),
          ),
          Positioned(
            bottom: -140,
            left: -120,
            child: _glowBlob(300, Colors.cyanAccent),
          ),

          /// 📄 CONTENT
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      20,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      /// 👑 BRAND
                      Column(
                        children: [
                          const Text("👑", style: TextStyle(fontSize: 42)),
                          const SizedBox(height: 6),
                          Text(
                            "Lucky Raja",
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.amberAccent,
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Play • Pick • Win Big 🎯",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 60),

                      /// 🧊 LOGIN CARD
                      ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 30,
                                  offset: Offset(0, 18),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  "Login with mobile",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "We’ll send an OTP to verify your number",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black.withOpacity(0.6),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                /// 📱 PHONE INPUT
                                TextField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  decoration: InputDecoration(
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        "+91",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    prefixIconConstraints: const BoxConstraints(
                                      minWidth: 0,
                                    ),
                                    hintText: "Mobile number",
                                    counterText: "",
                                    filled: true,
                                    fillColor: const Color(0xFFF2F0F7),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 26),

                                /// 🎯 CTA
                                SizedBox(
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: loading ? null : sendOtp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF7B2CFF),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 8,
                                      shadowColor: Colors.purpleAccent
                                          .withOpacity(0.6),
                                    ),
                                    child: loading
                                        ? const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          )
                                        : const Text(
                                            "CONTINUE",
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      /// 🔒 FOOTER
                      Text(
                        "100% Secure • OTP protected",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _glowBlob(double size, Color color) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withOpacity(0.25),
    ),
  );
}
