import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import 'statistics_screen.dart';
import 'history_screen.dart';
import 'add_transaction_screen.dart';
import 'transfer_bank_screen.dart';
import 'mood_analysis_screen.dart'; // ✅ TAMBAHAN NAVIGASI MOOD
import 'target_savings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double totalIncome = 0;
  double totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final transactions = await DatabaseService.loadTransactions();

    double income = 0;
    double expense = 0;

    for (var tx in transactions) {
      if (tx.type == 'income') {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    setState(() {
      totalIncome = income;
      totalExpense = expense;
    });
  }

  @override
  Widget build(BuildContext context) {
    double saldo = totalIncome - totalExpense;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          "DompetKu",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F2A5F),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F2A5F),
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddTransactionScreen(),
            ),
          );
          _loadData();
        },
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSaldoCard(saldo),
              const SizedBox(height: 30),
              _buildShortcutMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaldoCard(double saldo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2A5F), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Total Saldo",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Text(
            "Rp ${NumberFormat('#,##0', 'id_ID').format(saldo)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Pemasukan\nRp ${NumberFormat('#,##0', 'id_ID').format(totalIncome)}",
                style: const TextStyle(color: Colors.greenAccent),
              ),
              Text(
                "Pengeluaran\nRp ${NumberFormat('#,##0', 'id_ID').format(totalExpense)}",
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildShortcutMenu() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCircleButton(
            icon: Icons.swap_horiz_rounded,
            label: "Transfer",
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TransferBankScreen(),
                ),
              );
              _loadData();
            },
          ),
          const SizedBox(width: 25),
          _buildCircleButton(
            icon: Icons.bar_chart_rounded,
            label: "Statistik",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StatisticsScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 25),
          _buildCircleButton(
            icon: Icons.receipt_long_rounded,
            label: "Riwayat",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HistoryScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 25),

          // 🔥 ICON MOOD MONEY (SUDAH ADA NAVIGASI)
          _buildCircleButton(
            icon: Icons.psychology_rounded,
            label: "Mood Money",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MoodAnalysisScreen()
                ),
              );
            },
          ),

          const SizedBox(width: 25),
          _buildCircleButton(
            icon: Icons.savings_rounded,
            label: "Tabungan",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TargetSavingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}