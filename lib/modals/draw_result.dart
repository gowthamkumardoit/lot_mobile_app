class DrawResult {
  final String type; // 2D / 3D / 4D
  final String number;
  final int winners;
  final int totalWinAmount;

  DrawResult({
    required this.type,
    required this.number,
    required this.winners,
    required this.totalWinAmount,
  });

  factory DrawResult.fromDynamic(String type, dynamic value) {
    // 🟢 Winner case (object)
    if (value is Map<String, dynamic>) {
      return DrawResult(
        type: type,
        number: value['number']?.toString() ?? '',
        winners: value['winners'] ?? 0,
        totalWinAmount: value['totalWinAmount'] ?? 0,
      );
    }

    // 🔴 No-winner case (flat value)
    return DrawResult(
      type: type,
      number: value.toString(),
      winners: 0,
      totalWinAmount: 0,
    );
  }
}
