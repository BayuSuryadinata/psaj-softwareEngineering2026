import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? initialTx;

  const AddTransactionScreen({super.key, this.initialTx});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  late final _dateController = TextEditingController();

  String _selectedCategory = 'Makan';
  String _transactionType = 'expense';

  DateTime selectedDate = DateTime.now();

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

      final formattedAmount = NumberFormat('#,##0', 'id_ID').format(tx.amount);
      _amountController.text = 'Rp. $formattedAmount';
    }
  }

  void _updateDateField() {
    _dateController.text = "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
  }

  void _saveTransaction() async {
    final title = _descriptionController.text.trim();
    final amountText = _amountController.text.startsWith('Rp. ')
        ? _amountController.text.substring(4)
        : _amountController.text;
    final cleanAmount = amountText.replaceAll(RegExp(r'[^\d]'), '');

    if (title.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Judul wajib diisi!')),
        );
      }
      return;
    }

    if (cleanAmount.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jumlah wajib diisi!')),
        );
      }
      return;
    }

    double amount;
    try {
      amount = double.parse(cleanAmount);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jumlah harus angka!')),
        );
      }
      return;
    }

    if (amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jumlah harus > 0!')),
        );
      }
      return;
    }

    final newTx = Transaction(
      id: widget.initialTx?.id ?? DateTime.now().toString(),
      title: title,
      amount: amount,
      date: selectedDate,
      category: _selectedCategory,
      type: _transactionType,
      description: title,
    );

    List<Transaction> transactions = await DatabaseService.loadTransactions();
    if (widget.initialTx != null) {
      transactions.removeWhere((tx) => tx.id == widget.initialTx!.id);
    }
    transactions.add(newTx);
    await DatabaseService.saveTransactions(transactions);

    Navigator.pop(context, newTx);
  }

  void _deleteTransaction() async {
    if (widget.initialTx == null) return;

    final tx = widget.initialTx!;
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hapus Transaksi?'),
          content: Text('Apakah Anda yakin ingin menghapus "${tx.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);

                List<Transaction> transactions = await DatabaseService.loadTransactions();
                transactions.removeWhere((t) => t.id == tx.id);
                await DatabaseService.saveTransactions(transactions);

                Navigator.pop(context, 'deleted');
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }

  List<String> get _currentCategories =>
      _transactionType == 'expense' ? _expenseCategories : _incomeCategories;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _updateDateField();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialTx != null ? 'Edit Transaksi' : 'Buat Transaksi',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _transactionType = 'expense';
                            _selectedCategory = 'Makan';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _transactionType == 'expense'
                                ? Colors.red
                                : Colors.white,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Pengeluaran',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _transactionType = 'income';
                            _selectedCategory = 'Gaji';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _transactionType == 'income'
                                ? Colors.green
                                : Colors.white,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Pemasukan',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text('Tanggal', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      hintText: 'Pilih tanggal',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text('Kategori', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _currentCategories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Pilih kategori',
                ),
              ),
              const SizedBox(height: 16),

              Text('Jumlah', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  hintText: 'Rp. 100.000',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  if (value == 'Rp. ') return;

                  String clean = value.startsWith('Rp. ') ? value.substring(4) : value;
                  clean = clean.replaceAll(RegExp(r'[^\d]'), '');

                  if (clean.isEmpty) {
                    _amountController.text = 'Rp. ';
                    return;
                  }

                  int num = int.tryParse(clean) ?? 0;
                  String formatted = NumberFormat('#,##0', 'id_ID').format(num);
                  _amountController.text = 'Rp. $formatted';

                  _amountController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _amountController.text.length),
                  );
                },
              ),
              const SizedBox(height: 16),

              Text('Keterangan', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Gaji pertama / Beli makan siang',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 40),

              if (widget.initialTx != null)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          foregroundColor: Colors.grey,
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _deleteTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Hapus'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Simpan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}