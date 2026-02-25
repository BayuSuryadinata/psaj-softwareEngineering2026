import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/transaction.dart';
import '../models/mood.dart';

class MoodAnalysisScreen extends StatefulWidget {
  const MoodAnalysisScreen({super.key});

  @override
  State<MoodAnalysisScreen> createState() =>
      _MoodAnalysisScreenState();
}

class _MoodAnalysisScreenState
    extends State<MoodAnalysisScreen> {
  Map<String, double> moodTotals = {};
  double totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _analyzeData();
  }

  Future<void> _analyzeData() async {
    List<Transaction> transactions =
        await DatabaseService.loadTransactions();

    Map<String, double> temp = {};
    double total = 0;

    for (var tx in transactions) {
      if (tx.type == "expense") {
        total += tx.amount;
        temp[tx.mood] =
            (temp[tx.mood] ?? 0) + tx.amount;
      }
    }

    setState(() {
      moodTotals = temp;
      totalExpense = total;
    });
  }

  String _generateInsight() {
    if (moodTotals.isEmpty) {
      return "Belum ada data transaksi untuk dianalisis.";
    }

    var highest = moodTotals.entries
        .reduce((a, b) =>
            a.value > b.value ? a : b);

    MoodType mood = MoodType.values.firstWhere(
      (m) => m.name == highest.key,
      orElse: () => MoodType.calm,
    );

    return "Pengeluaran tertinggi terjadi saat kondisi ${mood.label}. "
        "Perhatikan pola ini agar keuangan lebih terkendali.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1F44),
        title: const Text(
          "Psychology of Money",
          style:
              TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: moodTotals.isEmpty
            ? const Center(
                child: Text(
                  "Belum ada data untuk dianalisis.",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w500),
                ),
              )
            : Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildTotalCard(),
                  const SizedBox(height: 25),
                  const Text(
                    "Rekap Pengeluaran Berdasarkan Emosi",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: ListView(
                      children: moodTotals.entries
                          .map((entry) =>
                              _buildMoodTile(
                                  entry.key,
                                  entry.value))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInsightCard(),
                ],
              ),
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0A1F44),
            Color(0xFF163E7A)
          ],
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            "Total Pengeluaran",
            style: TextStyle(
                color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            "Rp ${NumberFormat('#,##0', 'id_ID').format(totalExpense)}",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight:
                    FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodTile(
      String moodKey, double amount) {
    MoodType mood = MoodType.values.firstWhere(
      (m) => m.name == moodKey,
      orElse: () => MoodType.calm,
    );

    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black
                  .withOpacity(0.04),
              blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          Text(
            mood.emoji,
            style:
                const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mood.label,
              style: const TextStyle(
                  fontWeight:
                      FontWeight.w600),
            ),
          ),
          Text(
            "Rp ${NumberFormat('#,##0', 'id_ID').format(amount)}",
            style: const TextStyle(
                fontWeight:
                    FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard() {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF9),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Text(
        _generateInsight(),
        style: const TextStyle(
            fontWeight:
                FontWeight.w500),
      ),
    );
  }
}