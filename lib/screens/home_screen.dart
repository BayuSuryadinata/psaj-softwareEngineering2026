import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import 'add_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> _transactions = [];
  String _selectedTab = "Harian";

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final data = await DatabaseService.loadTransactions();
    setState(() {
      _transactions = data;
    });
  }

  double get totalIncome => _transactions
      .where((tx) => tx.type == "income")
      .fold(0, (sum, item) => sum + item.amount);

  double get totalExpense => _transactions
      .where((tx) => tx.type == "expense")
      .fold(0, (sum, item) => sum + item.amount);

  double get balance => totalIncome - totalExpense;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1F44),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "DompetKu",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 24),
            _buildTabSelector(),
            const SizedBox(height: 20),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0A1F44),
        onPressed: () async {
          final newTx = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddTransactionScreen()),
          );

          if (newTx != null) {
            _transactions.add(newTx);
            await DatabaseService.saveTransactions(_transactions);
            _loadTransactions();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1F44), Color(0xFF123B7A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Total Saldo",
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            "Rp ${NumberFormat('#,##0', 'id_ID').format(balance)}",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoItem("Pemasukan", totalIncome, Colors.greenAccent),
              _infoItem("Pengeluaran", totalExpense, Colors.redAccent),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    final tabs = ["Harian", "Mingguan", "Bulanan", "Tahunan"];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: tabs.map((tab) {
        final selected = _selectedTab == tab;
        return GestureDetector(
          onTap: () => setState(() => _selectedTab = tab),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF0A1F44) : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tab,
              style: TextStyle(
                  color: selected ? Colors.white : Colors.black54),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case "Harian":
        return _buildDaily();
      case "Mingguan":
        return _buildWeekly();
      case "Bulanan":
        return _buildMonthly();
      case "Tahunan":
        return _buildYearly();
      default:
        return _buildDaily();
    }
  }

  Widget _buildDaily() {
    return _buildTransactionList(_transactions);
  }

  Widget _buildWeekly() {
    final now = DateTime.now();
    final startWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekly = _transactions.where((tx) =>
        tx.date.isAfter(startWeek.subtract(const Duration(days: 1)))).toList();
    return _buildTransactionList(weekly);
  }

  Widget _buildMonthly() {
    final now = DateTime.now();
    final monthly = _transactions
        .where((tx) =>
            tx.date.month == now.month && tx.date.year == now.year)
        .toList();
    return _buildTransactionList(monthly);
  }

  Widget _buildYearly() {
    final now = DateTime.now();
    final yearly =
        _transactions.where((tx) => tx.date.year == now.year).toList();
    return _buildTransactionList(yearly);
  }

  Widget _buildTransactionList(List<Transaction> list) {
    if (list.isEmpty) {
      return const Center(child: Text("Belum ada transaksi"));
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final tx = list[index];
        final isIncome = tx.type == "income";

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05), blurRadius: 8)
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    isIncome ? Colors.green.shade50 : Colors.red.shade50,
                child: Icon(
                  isIncome
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    Text(DateFormat('dd MMM yyyy').format(tx.date),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Text(
                "${isIncome ? '+' : '-'} Rp ${NumberFormat('#,##0', 'id_ID').format(tx.amount)}",
                style: TextStyle(
                    color: isIncome ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _infoItem(String title, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white70, fontSize: 12)),
        Text(
          "Rp ${NumberFormat('#,##0', 'id_ID').format(value)}",
          style:
              TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}