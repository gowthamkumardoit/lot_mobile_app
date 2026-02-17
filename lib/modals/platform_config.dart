import 'package:mobile_app/modals/kyc_config.dart';

class PlatformConfig {
  final bool maintenanceMode;
  final String platformName;

  final bool withdrawalsDisabled;
  final int minWithdrawal;
  final int maxWithdrawalPerDay;

  final KycConfig kyc; // ✅ NEW

  PlatformConfig({
    required this.maintenanceMode,
    required this.platformName,
    required this.withdrawalsDisabled,
    required this.minWithdrawal,
    required this.maxWithdrawalPerDay,
    required this.kyc,
  });

  factory PlatformConfig.fromMap(Map<String, dynamic> data) {
    return PlatformConfig(
      maintenanceMode: data['general']?['maintenanceMode'] == true,
      platformName: data['general']?['platformName'] ?? "App",

      withdrawalsDisabled: data['danger']?['withdrawalsDisabled'] == true,
      minWithdrawal: data['wallet']?['minWithdrawal'] ?? 100,
      maxWithdrawalPerDay: data['wallet']?['maxWithdrawalPerDay'] ?? 0,

      kyc: KycConfig.fromMap(data['kyc']), // ✅
    );
  }
}
