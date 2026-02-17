import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:mobile_app/screens/app_shell.dart';
import 'package:permission_handler/permission_handler.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;

  const OtpScreen({super.key, required this.verificationId});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  // OTP boxes
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  bool loading = false;
  bool hasError = false;
  bool isSuccess = false;

  // Shake animation
  late AnimationController shakeController;
  late Animation<double> shakeAnimation;

  // Resend timer
  int resendSeconds = 30;
  Timer? resendTimer;

  @override
  void initState() {
    super.initState();

    shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12, end: -12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -12, end: 0), weight: 1),
    ]).animate(shakeController);

    startResendTimer();
  }

  @override
  void dispose() {
    shakeController.dispose();
    resendTimer?.cancel();
    for (final c in otpControllers) {
      c.dispose();
    }
    for (final f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> requestNotificationPermission() async {
    final status = await Permission.notification.status;

    if (status.isDenied || status.isRestricted) {
      await Permission.notification.request();
    }
  }

  // ================= OTP LOGIC =================

  String getOtp() {
    return otpControllers.map((e) => e.text).join();
  }

  Future<void> verifyOtp() async {
    final otp = getOtp();

    if (otp.length != 6) {
      triggerError();
      return;
    }

    setState(() => loading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // 🔥 REQUEST NOTIFICATION PERMISSION HERE
      await requestNotificationPermission();

      setState(() {
        isSuccess = true;
      });

      await Future.delayed(const Duration(milliseconds: 900));

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainLayout()),
        (_) => false,
      );
    } catch (_) {
      setState(() => loading = false);
      triggerError();
    }
  }

  void triggerError() {
    setState(() => hasError = true);
    shakeController.forward(from: 0);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Invalid OTP")));
  }

  // ================= RESEND OTP =================

  void startResendTimer() {
    resendSeconds = 30;
    resendTimer?.cancel();

    resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => resendSeconds--);
      }
    });
  }

  void resendOtp() {
    startResendTimer();
    // 🔁 You can call verifyPhoneNumber again here later
  }

  // ================= UI WIDGETS =================

  Widget otpBox(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError ? Colors.redAccent : const Color(0xFF9D4EDD),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: hasError
                ? Colors.redAccent.withOpacity(0.6)
                : const Color(0xFF9D4EDD).withOpacity(0.6),
            blurRadius: 12,
          ),
        ],
      ),
      child: TextField(
        controller: otpControllers[index],
        focusNode: focusNodes[index],
        maxLength: 1,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).requestFocus(focusNodes[index + 1]);
          }
        },
      ),
    );
  }

  Widget neonVerifyButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 1.05),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: loading ? null : verifyOtp,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF9D4EDD), Color(0xFF7B2CFF)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x809D4EDD),
                blurRadius: 30,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "VERIFY OTP",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ================= BACKGROUND GRADIENT =================
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0B0F2A), // deep navy
                  Color(0xFF1B0F4A), // royal blue
                  Color(0xFF2E026D), // deep purple
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ================= GLOW BLOBS =================
          Positioned(
            top: -120,
            right: -100,
            child: _glowBlob(260, const Color(0xFF9D4EDD)),
          ),
          Positioned(
            bottom: -140,
            left: -120,
            child: _glowBlob(300, const Color(0xFFE040FB)),
          ),

          // ================= CURVED ABSTRACT SHAPE =================
          Positioned(
            top: -200,
            left: -80,
            right: -80,
            child: Container(
              height: 420,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(300),
              ),
            ),
          ),

          // ================= CONTENT =================
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.9,
                              end: 1.0,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: isSuccess
                          ? Column(
                              key: const ValueKey('success'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF7B2CFF),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0xFF9D4EDD),
                                        blurRadius: 40,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 56,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Verified!",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Logging you in…",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              key: const ValueKey('otp'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedBuilder(
                                  animation: shakeAnimation,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(shakeAnimation.value, 0),
                                      child: child,
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: List.generate(6, otpBox),
                                  ),
                                ),
                                const SizedBox(height: 40),
                                neonVerifyButton(),
                                const SizedBox(height: 20),
                                TextButton(
                                  onPressed: resendSeconds == 0
                                      ? resendOtp
                                      : null,
                                  child: Text(
                                    resendSeconds == 0
                                        ? "RESEND OTP"
                                        : "Resend in $resendSeconds s",
                                    style: TextStyle(
                                      color: resendSeconds == 0
                                          ? const Color(0xFFE040FB)
                                          : Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
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
