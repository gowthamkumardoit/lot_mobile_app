import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class BankAccountsPage extends StatefulWidget {
  const BankAccountsPage({super.key});

  @override
  State<BankAccountsPage> createState() => _BankAccountsPageState();
}

class _BankAccountsPageState extends State<BankAccountsPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountName = TextEditingController();
  final _accountNumber = TextEditingController();
  final _ifsc = TextEditingController();
  final _bankName = TextEditingController();

  bool _loading = false;

  String? _processingId; // for setPrimary/delete spinner
  bool _savingAccount = false; // for add account spinner

  String mask(String number) => number.length <= 4
      ? number
      : "XXXX XXXX ${number.substring(number.length - 4)}";

  bool isValidName(String name) =>
      RegExp(r'^[A-Za-z ]{3,}$').hasMatch(name.trim());

  bool isValidAccountNumber(String number) =>
      RegExp(r'^[0-9]{9,18}$').hasMatch(number);

  bool isValidIFSC(String ifsc) =>
      RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc.toUpperCase());

  Future<void> addBankAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _savingAccount = true);

    try {
      await FirebaseFunctions.instanceFor(
        region: "asia-south1",
      ).httpsCallable('saveBankAccount').call({
        "accountName": _accountName.text.trim(),
        "accountNumber": _accountNumber.text.trim(),
        "ifsc": _ifsc.text.toUpperCase(),
        "bankName": _bankName.text.trim(),
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Sent for admin approval")));

      _accountName.clear();
      _accountNumber.clear();
      _ifsc.clear();
      _bankName.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _savingAccount = false);
  }

  Future<void> setPrimary(String id) async {
    setState(() => _processingId = id);

    try {
      await FirebaseFunctions.instanceFor(
        region: "asia-south1",
      ).httpsCallable('setPrimaryBankAccount').call({"bankAccountId": id});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Primary account updated")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed: $e")));
    }

    setState(() => _processingId = null);
  }

  Future<void> deleteAccount(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Bank Account"),
          content: const Text(
            "Are you sure you want to delete this bank account?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() => _processingId = id);

      try {
        await FirebaseFunctions.instanceFor(
          region: "asia-south1",
        ).httpsCallable('deleteBankAccount').call({"bankAccountId": id});

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Bank account deleted")));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
      }

      setState(() => _processingId = null);
    }
  }

  void showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Add Bank Account",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _accountName,
                  decoration: const InputDecoration(
                    labelText: "Account Holder Name",
                  ),
                  validator: (v) =>
                      v == null || !isValidName(v) ? "Letters only" : null,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _bankName,
                  decoration: const InputDecoration(labelText: "Bank Name"),
                  validator: (v) =>
                      v == null || !isValidName(v) ? "Letters only" : null,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _accountNumber,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Account Number",
                  ),
                  validator: (v) => v == null || !isValidAccountNumber(v)
                      ? "Invalid account number"
                      : null,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _ifsc,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: "IFSC Code"),
                  validator: (v) =>
                      v == null || !isValidIFSC(v) ? "Invalid IFSC" : null,
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : addBankAccount,
                    child: _savingAccount
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Submit"),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildAccountCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isPrimary = data['isPrimary'] ?? false;
    final status = data['status'];

    Color? statusColor;
    String? statusText;

    if (status == "PENDING") {
      statusColor = Colors.orange;
      statusText = "PENDING APPROVAL";
    } else if (status == "REJECTED") {
      statusColor = Colors.red;
      statusText = "REJECTED";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: isPrimary ? Border.all(color: Colors.green, width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Top Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data['bankName'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              if (isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "PRIMARY",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            mask(data['accountNumber']),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 6),

          Text(
            "IFSC: ${data['ifsc']}",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),

          const SizedBox(height: 10),

          /// STATUS BADGE
          if (!isPrimary && statusText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          const SizedBox(height: 12),

          if (status == "REJECTED" && data['adminNote'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Reason: ${data['adminNote']}",
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),

          /// Smaller Make Primary Button
          if (status == "APPROVED" && !isPrimary)
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 36,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => setPrimary(doc.id),
                  child: const Text(
                    "Make Primary",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => deleteAccount(doc.id),
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Bank Accounts")),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddSheet,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('bankAccounts')
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.toList();

          docs.sort((a, b) {
            final aPrimary = (a['isPrimary'] ?? false) ? 1 : 0;
            final bPrimary = (b['isPrimary'] ?? false) ? 1 : 0;
            return bPrimary.compareTo(aPrimary);
          });

          if (docs.isEmpty) {
            return const Center(child: Text("No bank accounts added yet"));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: docs.map(buildAccountCard).toList(),
          );
        },
      ),
    );
  }
}
