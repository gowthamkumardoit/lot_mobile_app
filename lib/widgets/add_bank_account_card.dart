import 'package:flutter/material.dart';

class AddBankAccountCard extends StatefulWidget {
  final Future<void> Function({
    required String accountName,
    required String accountNumber,
    required String ifsc,
    required String bankName,
  })
  onSubmit;

  const AddBankAccountCard({super.key, required this.onSubmit});

  @override
  State<AddBankAccountCard> createState() => _AddBankAccountCardState();
}

class _AddBankAccountCardState extends State<AddBankAccountCard> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _accountController = TextEditingController();
  final _confirmAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _bankController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _accountController.dispose();
    _confirmAccountController.dispose();
    _ifscController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    await widget.onSubmit(
      accountName: _nameController.text.trim(),
      accountNumber: _accountController.text.trim(),
      ifsc: _ifscController.text.trim().toUpperCase(),
      bankName: _bankController.text.trim(),
    );

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Add Bank Account",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              _buildField(
                controller: _nameController,
                label: "Account Holder Name",
                validator: (value) =>
                    value!.isEmpty ? "Enter account holder name" : null,
              ),

              _buildField(
                controller: _bankController,
                label: "Bank Name",
                validator: (value) => value!.isEmpty ? "Enter bank name" : null,
              ),

              _buildField(
                controller: _accountController,
                label: "Account Number",
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return "Enter account number";
                  if (value.length < 8) return "Invalid account number";
                  return null;
                },
              ),

              _buildField(
                controller: _confirmAccountController,
                label: "Confirm Account Number",
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != _accountController.text) {
                    return "Account numbers do not match";
                  }
                  return null;
                },
              ),

              _buildField(
                controller: _ifscController,
                label: "IFSC Code",
                validator: (value) {
                  if (value!.isEmpty) return "Enter IFSC code";
                  if (value.length != 11) return "Invalid IFSC code";
                  return null;
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Save Bank Account"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
