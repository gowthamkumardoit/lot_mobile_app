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
  int resendSeconds = 60;
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
        color: const Color.fromARGB(255, 0, 0, 0),
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
            blurRadius: 10,
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
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
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
                            color: primary,
                            boxShadow: [
                              BoxShadow(
                                color: primary.withOpacity(0.3),
                                blurRadius: 25,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 56,
                            color: onPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Verified!",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Logging you in…",
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    )
                  : Column(
                      key: const ValueKey('otp'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Enter OTP",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "We’ve sent a 6-digit code",
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 40),

                        /// OTP BOXES WITH SHAKE
                        AnimatedBuilder(
                          animation: shakeAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(shakeAnimation.value, 0),
                              child: child,
                            );
                          },
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final totalWidth = constraints.maxWidth;
                              final boxWidth =
                                  (totalWidth - 50) / 6; // 50 = total spacing

                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  6,
                                  (index) => SizedBox(
                                    width: boxWidth,
                                    height: 60,
                                    child: _themedOtpBox(index),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 40),

                        /// VERIFY BUTTON (THEME BASED)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: loading ? null : verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent, // force red
                              foregroundColor: Colors.white, // force white text
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: loading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: onPrimary,
                                    ),
                                  )
                                : const Text(
                                    "VERIFY OTP",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// RESEND
                        TextButton(
                          onPressed: resendSeconds == 0 ? resendOtp : null,
                          child: Text(
                            resendSeconds == 0
                                ? "RESEND OTP"
                                : "Resend in $resendSeconds s",
                            style: TextStyle(
                              color: resendSeconds == 0
                                  ? primary
                                  : Colors.black45,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _themedOtpBox(int index) {
    return SizedBox(
      width: 55,
      height: 60,
      child: TextField(
        controller: otpControllers[index],
        focusNode: focusNodes[index],
        maxLength: 1,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Colors.black,
          height: 1.2, // 🔥 important
        ),
        cursorColor: Colors.redAccent,
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12, // 🔥 gives breathing space
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).requestFocus(focusNodes[index + 1]);
          }
          if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(focusNodes[index - 1]);
          }
        },
      ),
    );
  }
}
