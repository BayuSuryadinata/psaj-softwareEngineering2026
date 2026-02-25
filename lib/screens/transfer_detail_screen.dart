import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../models/mood.dart';
import 'package:intl/intl.dart';

class TransferDetailScreen extends StatefulWidget {
  final String selectedBank;

  const TransferDetailScreen({
    super.key,
    required this.selectedBank,
  });

  @override
  State<TransferDetailScreen> createState() =>
      _TransferDetailScreenState();
}

class _TransferDetailScreenState extends State<TransferDetailScreen> {
  final _accountController = TextEditingController();
  final _amountController = TextEditingController();

  MoodType? selectedMood;

  double currentBalance = 0;
  List<Transaction> allTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final transactions = await DatabaseService.loadTransactions();

    double income = 0;
    double expense = 0;

    for (var t in transactions) {
      if (t.type == "income") {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }

    setState(() {
      allTransactions = transactions;
      currentBalance = income - expense;
    });
  }

  Future<void> _submitTransfer() async {
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (_accountController.text.isEmpty ||
        amount <= 0 ||
        selectedMood == null) {
      _showMessage("Lengkapi semua data dan pilih mood terlebih dahulu.");
      return;
    }

    if (amount > currentBalance) {
      _showMessage("Saldo tidak mencukupi.");
      return;
    }

    final newTransaction = Transaction(
      id: const Uuid().v4(),
      title: "Transfer",
      amount: amount,
      date: DateTime.now(),
      category: "Transfer",
      type: "expense",
      description:
          "Transfer ke ${widget.selectedBank} - ${_accountController.text}",
      mood: selectedMood!.name,
    );

    allTransactions.add(newTransaction);
    await DatabaseService.saveTransactions(allTransactions);

    if (context.mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Informasi"),
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Detail Transfer"),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F2A5F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance,
                      color: Colors.white, size: 30),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      widget.selectedBank,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            TextField(
              controller: _accountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Nomor Rekening",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Nominal Transfer",
                prefixText: "Rp ",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                "Bagaimana perasaan Anda saat transaksi ini?",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              children: MoodType.values.map((mood) {
                final isSelected = selectedMood == mood;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedMood = mood;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1E3A8A)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    child: Text(
                      "${mood.emoji} ${mood.label}", // emoji hanya disini
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 15),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Saldo tersedia: Rp ${NumberFormat('#,##0', 'id_ID').format(currentBalance)}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitTransfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F2A5F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  "Kirim Sekarang",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}