import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/modals/wallet_modal.dart';
import 'package:mobile_app/services/wallet_service.dart';
import '../../modals/digit_draw_slot.dart';
import 'dart:math';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TicketPurchasePage extends StatefulWidget {
  final DigitDrawSlot slot;

  const TicketPurchasePage({super.key, required this.slot});

  @override
  State<TicketPurchasePage> createState() => _TicketPurchasePageState();
}

class _TicketPurchasePageState extends State<TicketPurchasePage>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();

  Set<String> selectedTickets = {};

  late TabController _tabController;
  late List<int> rangeStarts;
  late AnimationController glowController;

  DateTime? _holdExpiry;
  Timer? _holdTimer;
  int _remainingSeconds = 0;
  bool _isHolding = false;

  Set<String> bookedNumbers = {};
  Set<String> heldByOthers = {};
  StreamSubscription? _seatSubscription;

  Future<void> addTicket(String number) async {
    if (selectedTickets.contains(number)) return;

    setState(() {
      selectedTickets.add(number);
    });

    await _createHold(); // 🔥 always update hold
  }

  Future<void> _createHold() async {
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'asia-south1',
      ).httpsCallable('holdKuberGoldNumbers');

      final result = await callable.call({
        "slotId": widget.slot.id,
        "numbers": selectedTickets.toList(),
      });

      final holdUntilMillis = result.data["holdUntil"];

      _holdExpiry = DateTime.fromMillisecondsSinceEpoch(holdUntilMillis);

      _isHolding = true;

      _startHoldTimer();
    } on FirebaseFunctionsException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Hold failed")));
    }
  }

  void _startHoldTimer() {
    _holdTimer?.cancel();

    _holdTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_holdExpiry == null) return;

      final remaining = _holdExpiry!.difference(DateTime.now()).inSeconds;

      if (remaining <= 0) {
        timer.cancel();
        _releaseHoldLocally();
      } else {
        setState(() {
          _remainingSeconds = remaining;
        });
      }
    });
  }

  void _releaseHoldLocally() {
    setState(() {
      selectedTickets.clear();
      _isHolding = false;
      _remainingSeconds = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Reservation expired"),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> removeTicket(String number) async {
    setState(() {
      selectedTickets.remove(number);
    });

    if (selectedTickets.isEmpty) {
      _releaseHoldLocally();
    } else {
      await _createHold(); // refresh hold with remaining tickets
    }
  }

  int get totalCount => selectedTickets.length;
  int get totalAmount => totalCount * widget.slot.ticketPrice;

  Future<void> _handlePurchase() async {
    setState(() => _isPurchasing = true);

    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'asia-south1',
      ).httpsCallable('purchaseKuberGoldTicket');

      await callable.call({
        "slotId": widget.slot.id,
        "numbers": {for (var n in selectedTickets) n: 1},
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tickets purchased successfully"),
          backgroundColor: Colors.green,
        ),
      );

      _holdTimer?.cancel();

      setState(() {
        selectedTickets.clear();
        _isHolding = false;
        _remainingSeconds = 0;
      });
    } on FirebaseFunctionsException catch (e) {
      // 🔥 Show backend error message
      final message = e.message ?? "Something went wrong";

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unexpected error occurred"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    final digits = widget.slot.digits;
    final maxNumber = pow(10, digits).toInt();

    // Create ranges of 100
    rangeStarts = List.generate((maxNumber / 100).ceil(), (i) => i * 100);

    _tabController = TabController(length: rangeStarts.length, vsync: this);

    glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _listenToSeats(); // 🔥 add this
  }

  @override
  void dispose() {
    glowController.dispose();
    _controller.dispose();
    _tabController.dispose();
    _holdTimer?.cancel();
    _seatSubscription?.cancel();
    super.dispose();
  }

  void _listenToSeats() {
    final slotId = widget.slot.id;

    _seatSubscription = FirebaseFirestore.instance
        .collection("digitDrawSlots")
        .doc(slotId)
        .collection("bookedNumbers")
        .snapshots()
        .listen((snapshot) {
          final newBooked = <String>{};
          final newHeldByOthers = <String>{};

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final status = data["status"];
            final userId = data["userId"];
            final holdUntil = data["holdUntil"];

            final number = doc.id;

            // BOOKED → permanently blocked
            if (status == "BOOKED") {
              newBooked.add(number);
            }
            final currentUser = FirebaseAuth.instance.currentUser?.uid;
            // HOLD by other user and not expired
            if (status == "HOLD" && userId != null && userId != currentUser) {
              if (holdUntil != null &&
                  holdUntil.toDate().isAfter(DateTime.now())) {
                newHeldByOthers.add(number);
              }
            }
          }

          setState(() {
            bookedNumbers = newBooked;
            heldByOthers = newHeldByOthers;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final digits = widget.slot.digits;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text("${digits} Digit Ticket"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: digits == 2
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.deepOrange,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.deepOrange,
                tabs: rangeStarts.map((start) {
                  final end = start + 99;
                  final formattedStart = start.toString().padLeft(digits, '0');
                  final formattedEnd = end.toString().padLeft(digits, '0');

                  return Tab(text: "$formattedStart-$formattedEnd");
                }).toList(),
              ),
      ),
      body: Column(
        children: [
          /// Manual Entry
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    maxLength: digits,
                    decoration: InputDecoration(
                      hintText: "Enter $digits digit number",
                      counterText: "",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    final value = _controller.text.padLeft(digits, '0');

                    if (value.length == digits) {
                      addTicket(value);
                      _controller.clear();
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            ),
          ),

          /// Grid Section
          Expanded(
            child: digits == 2
                ? buildGrid(0, 99)
                : TabBarView(
                    controller: _tabController,
                    children: rangeStarts.map((start) {
                      return buildGrid(start, start + 99);
                    }).toList(),
                  ),
          ),

          /// Bottom Summary
          buildBottomSummary(),
        ],
      ),
    );
  }

  Widget buildGrid(int start, int end) {
    final digits = widget.slot.digits;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: 100,
      itemBuilder: (_, index) {
        final number = (start + index).toString().padLeft(digits, '0');

        final isSelected = selectedTickets.contains(number);
        final isBooked = bookedNumbers.contains(number);
        final isHeldByOther = heldByOthers.contains(number);

        return GestureDetector(
          onTap: () {
            if (isBooked || isHeldByOther) return;

            if (isSelected) {
              removeTicket(number);
            } else {
              addTicket(number);
            }
          },
          child: AnimatedScale(
            duration: const Duration(milliseconds: 180),
            scale: isSelected ? 1.1 : 1.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,

                // 🎨 COLOR LOGIC
                gradient: isBooked
                    ? const LinearGradient(
                        colors: [Colors.grey, Colors.black54],
                      )
                    : isHeldByOther
                    ? const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFD32F2F)],
                      )
                    : isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFE5E5E5)],
                      ),

                boxShadow: isSelected
                    ? [
                        const BoxShadow(
                          color: Colors.orangeAccent,
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ]
                    : [
                        const BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
              ),
              child: Center(
                child: Text(
                  number,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isBooked || isHeldByOther
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isPurchasing = false;

  Widget buildBottomSummary() {
    return StreamBuilder<WalletBalance>(
      stream: WalletService().getWalletBalances(
        FirebaseAuth.instance.currentUser!.uid,
      ),
      builder: (context, snap) {
        final balance =
            snap.data ?? WalletBalance(wallet: 0, locked: 0, bonus: 0);

        final total = totalAmount;
        final bonusBalance = balance.bonus;

        final maxBonusAllowed = (total * 0.10).floor();
        final bonusToUse = bonusBalance > 0
            ? min(bonusBalance, maxBonusAllowed)
            : 0;

        final payable = total - bonusToUse;

        return SafeArea(
          top: false,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Ticket Info Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$totalCount Tickets",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₹${widget.slot.ticketPrice} each",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "₹${NumberFormat("#,##,###").format(total)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// Bonus Breakdown
                _buildSummaryContent(bonusToUse: bonusToUse, payable: payable),

                const SizedBox(height: 16),

                if (_isHolding)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      "Reserved for ${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}",
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                /// Buy Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: totalCount == 0 || _isPurchasing
                        ? null
                        : _handlePurchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isPurchasing
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Buy Now",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryContent({required int bonusToUse, required int payable}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Tickets Total"),
            Text("₹${NumberFormat("#,##,###").format(totalAmount)}"),
          ],
        ),

        if (bonusToUse > 0) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Bonus Applied (10%)",
                style: TextStyle(color: Colors.green),
              ),
              Text(
                "-₹${NumberFormat("#,##,###").format(bonusToUse)}",
                style: const TextStyle(color: Colors.green),
              ),
            ],
          ),
        ],

        const Divider(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "You Pay",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "₹${NumberFormat("#,##,###").format(payable)}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ],
    );
  }
}
