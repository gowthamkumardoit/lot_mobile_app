class WalletBalance {
  final int wallet;
  final int locked;

  WalletBalance({required this.wallet, required this.locked});

  int get available => (wallet - locked).clamp(0, wallet);
}
