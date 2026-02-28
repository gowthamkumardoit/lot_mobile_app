import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_gradients.dart';
import '../../screens/wallet/wallet_page.dart';
import '../../screens/app_shell.dart';
class LotteryHeader extends StatelessWidget {
  final String balance;
  final int notificationCount;
  final String? avatarUrl; // 🔥 Add this

  const LotteryHeader({
    super.key,
    required this.balance,
    required this.notificationCount,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: AppGradients.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// 👤 PROFILE IMAGE WITH FALLBACK
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withOpacity(0.2),
            backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                ? NetworkImage(avatarUrl!)
                : const AssetImage("assets/images/avatar.png") as ImageProvider,
            onBackgroundImageError: (_, __) {},
          ),

          /// 🎯 CENTER TITLE
          Expanded(
            child: Center(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFFFFFFFF), // pure white highlight
                    Color(0xFFFFF3C4), // soft gold
                    Color(0xFFFFD54F), // rich gold
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: const Text(
                  "KUBER LOTTERY",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                    color: Colors.white, // required for shader
                    shadows: [
                      // strong depth shadow
                      Shadow(
                        offset: Offset(0, 4),
                        blurRadius: 8,
                        color: Color(0xAA000000),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// 💎 WALLET (Clickable)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                 MainLayout.of(context)?.setTab(3);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          balance,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
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
