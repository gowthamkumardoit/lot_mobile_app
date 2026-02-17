class KycConfig {
  final int gracePeriodDays;
  final int requiredAboveAmount;
  final bool requiredForWithdrawals;

  KycConfig({
    required this.gracePeriodDays,
    required this.requiredAboveAmount,
    required this.requiredForWithdrawals,
  });

  factory KycConfig.fromMap(Map<String, dynamic>? data) {
    return KycConfig(
      gracePeriodDays: data?['gracePeriodDays'] ?? 0,
      requiredAboveAmount: data?['requiredAboveAmount'] ?? 0,
      requiredForWithdrawals: data?['requiredForWithdrawals'] ?? false,
    );
  }
}
