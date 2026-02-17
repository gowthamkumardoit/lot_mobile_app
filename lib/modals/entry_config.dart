import '../modals/draw_run.dart';
import '../services/ticket_service.dart';

enum EntryType { twoD, threeD, fourD }

class EntryConfig {
  final EntryType type;
  final int digits;
  final int multiplier;
  final String title;
  final Future<void> Function(Map<String, int>) onSubmit;

  EntryConfig({
    required this.type,
    required this.digits,
    required this.multiplier,
    required this.title,
    required this.onSubmit,
  });

  factory EntryConfig.twoD(DrawRun draw) {
    return EntryConfig(
      type: EntryType.twoD,
      digits: 2,
      multiplier: draw.multiplier2D,
      title: "2D Entry",
      onSubmit: (numbers) {
        return TicketService().purchase2DTicket(
          drawId: draw.id,
          numbers: numbers,
        );
      },
    );
  }

  factory EntryConfig.threeD(DrawRun draw) {
    return EntryConfig(
      type: EntryType.threeD,
      digits: 3,
      multiplier: draw.multiplier3D,
      title: "3D Entry",
      onSubmit: (numbers) {
        return TicketService().purchase3DTicket(
          drawId: draw.id,
          numbers: numbers,
        );
      },
    );
  }

  factory EntryConfig.fourD(DrawRun draw) {
    return EntryConfig(
      type: EntryType.fourD,
      digits: 4,
      multiplier: draw.multiplier4D,
      title: "4D Entry",
      onSubmit: (numbers) {
        return TicketService().purchase4DTicket(
          drawId: draw.id,
          numbers: numbers,
        );
      },
    );
  }
}
