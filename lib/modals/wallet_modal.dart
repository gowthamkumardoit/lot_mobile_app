class WalletBalance {
  final int wallet;
  final int locked;
  final int bonus;
  final DateTime? bonusExpiry; // make it final

  WalletBalance({
    required this.wallet,
    required this.locked,
    required this.bonus,
    this.bonusExpiry, // add here
  });

  int get available => (wallet - locked).clamp(0, wallet);
}
