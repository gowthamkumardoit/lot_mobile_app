import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/modals/wallet_txn.dart';

enum TxnFilter { all, credit, debit }

class WalletHistoryPage extends StatefulWidget {
  const WalletHistoryPage({super.key});

  static const bg = Color(0xFF0B1220);
  static const surface = Color(0xFF11172C);
  static const credit = Color(0xFF2EFF7A);
  static const debit = Color(0xFFFF5C5C);

  @override
  State<WalletHistoryPage> createState() => _WalletHistoryPageState();
}

class _WalletHistoryPageState extends State<WalletHistoryPage> {
  final ScrollController _scrollController = ScrollController();

  final List<WalletTxn> _txns = [];
  DocumentSnapshot? _lastDoc;

  bool _isLoading = false;
  bool _hasMore = true;

  static const int _pageSize = 20;
  TxnFilter _filter = TxnFilter.all;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    final userId = FirebaseAuth.instance.currentUser!.uid;

    Query query = FirebaseFirestore.instance
        .collection("walletTxns")
        .where("userId", isEqualTo: userId)
        .orderBy("createdAt", descending: true)
        .limit(_pageSize);

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snap = await query.get();

    if (snap.docs.isNotEmpty) {
      _lastDoc = snap.docs.last;
      _txns.addAll(snap.docs.map((d) => WalletTxn.fromDoc(d)).toList());
    }

    if (snap.docs.length < _pageSize) {
      _hasMore = false;
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: WalletHistoryPage.bg,
        body: Center(
          child: Text("Please login", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final filteredTxns = _txns.where((t) {
      if (_filter == TxnFilter.credit) return t.amount > 0;
      if (_filter == TxnFilter.debit) return t.amount < 0;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: WalletHistoryPage.bg,
      appBar: AppBar(
        backgroundColor: WalletHistoryPage.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Wallet History",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // 🔍 FILTERS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                _filterChip("All", TxnFilter.all),
                _filterChip("Credit", TxnFilter.credit),
                _filterChip("Debit", TxnFilter.debit),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 📜 LIST
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: filteredTxns.length + 1,
              itemBuilder: (context, index) {
                if (index == filteredTxns.length) {
                  if (!_hasMore) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          "No more transactions",
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    );
                  }
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final t = filteredTxns[index];
                final isCredit = t.amount > 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: WalletHistoryPage.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isCredit
                                ? WalletHistoryPage.credit
                                : WalletHistoryPage.debit,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.reason,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${t.createdAt}",
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "${isCredit ? '+' : '-'}₹${t.amount.abs()}",
                          style: TextStyle(
                            color: isCredit
                                ? WalletHistoryPage.credit
                                : WalletHistoryPage.debit,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, TxnFilter value) {
    final selected = _filter == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: Colors.blueAccent,
      backgroundColor: const Color(0xFF1A2240),
      shape: StadiumBorder(
        side: BorderSide(color: selected ? Colors.blueAccent : Colors.white24),
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.white70,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
