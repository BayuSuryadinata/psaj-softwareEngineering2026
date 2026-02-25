import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../models/mood.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? initialTx;

  const AddTransactionScreen({super.key, this.initialTx});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();

  String _selectedCategory = 'Makan';
  String _transactionType = 'expense';

  DateTime selectedDate = DateTime.now();
  MoodType? _selectedMood;

  final List<String> _expenseCategories = [
    'Makan',
    'Transport',
    'Belanja',
    'Tagihan',
    'Hiburan',
  ];

  final List<String> _incomeCategories = [
    'Gaji',
    'Bonus',
    'Investasi',
  ];

  @override
  void initState() {
    super.initState();
    _amountController.text = 'Rp. ';
    _updateDateField();

    if (widget.initialTx != null) {
      final tx = widget.initialTx!;
      _descriptionController.text = tx.title;
      _selectedCategory = tx.category;
      _transactionType = tx.type;
      selectedDate = tx.date;
      _updateDateField();

      final formattedAmount =
          NumberFormat('#,##0', 'id_ID').format(tx.amount);
      _amountController.text = 'Rp. $formattedAmount';

      // 🔥 LOAD MOOD SAAT EDIT
      _selectedMood = MoodType.values.firstWhere(
        (m) => m.name == tx.mood,
        orElse: () => MoodType.calm,
      );
    }
  }

  void _updateDateField() {
    _dateController.text =
        "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
  }

  List<String> get _currentCategories =>
      _transactionType == 'expense'
          ? _expenseCategories
          : _incomeCategories;

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _updateDateField();
      });
    }
  }

  void _saveTransaction() async {
    final title = _descriptionController.text.trim();
    final amountText = _amountController.text.startsWith('Rp. ')
        ? _amountController.text.substring(4)
        : _amountController.text;

    final cleanAmount =
        amountText.replaceAll(RegExp(r'[^\d]'), '');

    if (title.isEmpty ||
        cleanAmount.isEmpty ||
        _selectedMood == null) {
      _showMessage("Lengkapi semua data dan pilih mood.");
      return;
    }

    double amount = double.parse(cleanAmount);

    final newTx = Transaction(
      id: widget.initialTx?.id ?? DateTime.now().toString(),
      title: title,
      amount: amount,
      date: selectedDate,
      category: _selectedCategory,
      type: _transactionType,
      description: title,
      mood: _selectedMood!.name,
    );

    List<Transaction> transactions =
        await DatabaseService.loadTransactions();

    if (widget.initialTx != null) {
      transactions.removeWhere(
          (tx) => tx.id == widget.initialTx!.id);
    }

    transactions.add(newTx);
    await DatabaseService.saveTransactions(transactions);

    Navigator.pop(context, newTx);
  }

  void _showMessage(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Informasi"),
        content: Text(msg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1F44),
        centerTitle: true,
        title: Text(
          widget.initialTx != null
              ? 'Edit Transaksi'
              : 'Buat Transaksi',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 25),

            _buildCardField(
              title: "Tanggal",
              child: GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextField(
                    controller: _dateController,
                    decoration:
                        _inputDecoration("Pilih tanggal"),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            _buildCardField(
              title: "Kategori",
              child: DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _currentCategories
                    .map((cat) => DropdownMenuItem(
                        value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                decoration:
                    _inputDecoration("Pilih kategori"),
              ),
            ),

            const SizedBox(height: 16),

            _buildCardField(
              title: "Jumlah",
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration:
                    _inputDecoration("Rp. 100000"),
              ),
            ),

            const SizedBox(height: 16),

            _buildCardField(
              title: "Keterangan",
              child: TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration:
                    _inputDecoration("Contoh: Gaji / Beli makan"),
              ),
            ),

            const SizedBox(height: 16),

            // 🔥 MOOD CARD
            _buildCardField(
              title: "Kondisi Emosi Saat Transaksi",
              child: Wrap(
                spacing: 10,
                children: MoodType.values.map((mood) {
                  final isSelected =
                      _selectedMood == mood;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMood = mood;
                      });
                    },
                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0A1F44)
                            : Colors.white,
                        borderRadius:
                            BorderRadius.circular(30),
                        border: Border.all(
                          color:
                              const Color(0xFF0A1F44),
                        ),
                      ),
                      child: Text(
                        "${mood.emoji} ${mood.label}",
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.black87,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF0A1F44),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Simpan",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _typeButton("expense", "Pengeluaran"),
          _typeButton("income", "Pemasukan"),
        ],
      ),
    );
  }

  Widget _typeButton(String value, String label) {
    final selected = _transactionType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _transactionType = value;
            _selectedCategory =
                value == "expense"
                    ? _expenseCategories.first
                    : _incomeCategories.first;
          });
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF0A1F44)
                : Colors.transparent,
            borderRadius:
                BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardField(
      {required String title,
      required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black
                  .withOpacity(0.04),
              blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          child
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
      String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor:
          const Color(0xFFF4F6FA),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}