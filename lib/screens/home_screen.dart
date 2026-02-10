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
  String _selectedTab = 'Harian';

  final List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final loadedTransactions = await DatabaseService.loadTransactions();
    setState(() {
      _transactions = loadedTransactions;
    });
  }

  double get totalIncome {
    return _transactions
        .where((tx) => tx.type == 'income')
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get totalExpense {
    return _transactions
        .where((tx) => tx.type == 'expense')
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get balance => totalIncome - totalExpense;

  // Fungsi: Dapatkan rentang minggu ke-n di bulan tertentu
  DateTimeRange getWeekRange(int weekNumber, DateTime monthStart) {
    final startDay = (weekNumber - 1) * 7 + 1;
    final endDay = weekNumber == 4
        ? DateTime(monthStart.year, monthStart.month + 1, 0).day
        : startDay + 6;

    final startDate = DateTime(monthStart.year, monthStart.month, startDay);
    final endDate = DateTime(monthStart.year, monthStart.month, endDay);

    return DateTimeRange(start: startDate, end: endDate);
  }

  // Hitung total per minggu
  Map<String, double> calculateWeeklyTotals(DateTimeRange range) {
    final income = _transactions
        .where((tx) =>
            tx.type == 'income' &&
            (tx.date.isAtSameMomentAs(range.start) || tx.date.isAfter(range.start)) &&
            (tx.date.isAtSameMomentAs(range.end) || tx.date.isBefore(range.end)))
        .fold(0.0, (sum, tx) => sum + tx.amount);

    final expense = _transactions
        .where((tx) =>
            tx.type == 'expense' &&
            (tx.date.isAtSameMomentAs(range.start) || tx.date.isAfter(range.start)) &&
            (tx.date.isAtSameMomentAs(range.end) || tx.date.isBefore(range.end)))
        .fold(0.0, (sum, tx) => sum + tx.amount);

    return {
      'income': income,
      'expense': expense,
      'balance': income - expense,
    };
  }

  // Hitung total per bulan untuk tahun tertentu
  Map<String, Map<String, double>> calculateMonthlyTotals(int year) {
    final Map<String, Map<String, double>> monthlyTotals = {};

    for (int month = 1; month <= 12; month++) {
      final monthKey = '${_monthNames[month - 1]}';
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0); // akhir bulan

      final income = _transactions
          .where((tx) =>
              tx.type == 'income' &&
              tx.date.isAfter(startOfMonth.subtract(Duration(days: 1))) &&
              tx.date.isBefore(endOfMonth.add(Duration(days: 1))))
          .fold(0.0, (sum, tx) => sum + tx.amount);

      final expense = _transactions
          .where((tx) =>
              tx.type == 'expense' &&
              tx.date.isAfter(startOfMonth.subtract(Duration(days: 1))) &&
              tx.date.isBefore(endOfMonth.add(Duration(days: 1))))
          .fold(0.0, (sum, tx) => sum + tx.amount);

      monthlyTotals[monthKey] = {
        'income': income,
        'expense': expense,
        'balance': income - expense,
      };
    }

    return monthlyTotals;
  }

  // Hitung total per tahun (hanya tahun yang ada transaksinya)
  Map<int, Map<String, double>> calculateYearlyTotals() {
    final Map<int, Map<String, double>> yearlyTotals = {};

    for (final tx in _transactions) {
      final year = tx.date.year;
      yearlyTotals.putIfAbsent(year, () => {'income': 0.0, 'expense': 0.0, 'balance': 0.0});

      final data = yearlyTotals[year]!;
      if (tx.type == 'income') {
        data['income'] = (data['income'] as double) + tx.amount;
      } else if (tx.type == 'expense') {
        data['expense'] = (data['expense'] as double) + tx.amount;
      }
      data['balance'] = (data['income'] as double) - (data['expense'] as double);
    }

    // Urutkan tahun dari terbaru ke terlama
    return Map.fromEntries(
      yearlyTotals.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  // Format rentang tanggal: "01–07"
  String formatWeekRange(DateTimeRange range) {
    final start = '${range.start.day}';
    final end = '${range.end.day}';
    return '$start–$end';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthName = DateFormat('MMMM yyyy', 'id_ID').format(monthStart);
    final currentYear = now.year;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dompet', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tab Bar
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
                        setState(() => _selectedTab = 'Harian');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTab == 'Harian' ? Colors.blue : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'Harian',
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
                        setState(() => _selectedTab = 'Mingguan');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTab == 'Mingguan' ? Colors.blue : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'Mingguan',
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
                        setState(() => _selectedTab = 'Bulanan');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTab == 'Bulanan' ? Colors.blue : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'Bulanan',
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
                        setState(() => _selectedTab = 'Tahunan');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTab == 'Tahunan' ? Colors.blue : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'Tahunan',
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

            // Tab Harian
            if (_selectedTab == 'Harian')
              Expanded(
                child: Column(
                  children: [
                    // Summary Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pemasukan', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  Text(
                                    'Rp. ${NumberFormat('#,##0', 'id_ID').format(totalIncome)}',
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pengeluaran', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  Text(
                                    'Rp. ${NumberFormat('#,##0', 'id_ID').format(totalExpense)}',
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Saldo', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  Text(
                                    'Rp. ${NumberFormat('#,##0', 'id_ID').format(balance)}',
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Daftar Transaksi
                    Expanded(
                      child: _transactions.isEmpty
                          ? const Center(child: Text('Belum ada transaksi'))
                          : ListView.builder(
                              itemCount: _transactions.length,
                              itemBuilder: (context, index) {
                                final tx = _transactions[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  child: ListTile(
                                    title: Text(tx.title),
                                    subtitle: Text('${tx.category} • ${tx.date.toString().split(' ')[0]}'),
                                    trailing: Text(
                                      'Rp. ${NumberFormat('#,##0', 'id_ID').format(tx.amount)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: tx.type == 'income' ? Colors.green : Colors.red,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddTransactionScreen(initialTx: tx),
                                        ),
                                      ).then((result) {
                                        if (result == 'deleted' || result != null) {
                                          Future.delayed(const Duration(milliseconds: 100), () {
                                            _loadTransactions();
                                          });
                                        }
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),

            // Tab Mingguan
            if (_selectedTab == 'Mingguan')
              Expanded(
                child: Column(
                  children: List.generate(4, (index) {
                    final weekNum = index + 1;
                    final weekRange = getWeekRange(weekNum, monthStart);
                    final totals = calculateWeeklyTotals(weekRange);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Minggu $weekNum', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    formatWeekRange(weekRange),
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            Flexible(
                              child: Text(
                                'Rp. ${NumberFormat('#,##0', 'id_ID').format(totals['income'] ?? 0)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                'Rp. ${NumberFormat('#,##0', 'id_ID').format(totals['expense'] ?? 0)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                'Rp. ${NumberFormat('#,##0', 'id_ID').format(totals['balance'] ?? 0)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),

            // Tab Bulanan
            if (_selectedTab == 'Bulanan')
              Expanded(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pemasukan', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  Text(
                                    'Rp. ${NumberFormat('#,##0', 'id_ID').format(totalIncome)}',
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pengeluaran', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  Text(
                                    'Rp. ${NumberFormat('#,##0', 'id_ID').format(totalExpense)}',
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Saldo', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  Text(
                                    'Rp. ${NumberFormat('#,##0', 'id_ID').format(balance)}',
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final monthKey = _monthNames[index];
                          final monthlyTotals = calculateMonthlyTotals(currentYear);
                          final data = monthlyTotals[monthKey] ?? {'income': 0.0, 'expense': 0.0, 'balance': 0.0};
                          final income = data['income']!;
                          final expense = data['expense']!;
                          final balance = data['balance']!;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: ListTile(
                              title: Text(monthKey, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '$monthKey $currentYear',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Rp. ${NumberFormat('#,##0', 'id_ID').format(income)}',
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Rp. ${NumberFormat('#,##0', 'id_ID').format(expense)}',
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Rp. ${NumberFormat('#,##0', 'id_ID').format(balance)}',
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
              ),

            // Tab Tahunan
            if (_selectedTab == 'Tahunan')
              Expanded(
                child: Column(
                  children: [
                    // Summary Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pemasukan', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  Text(
                                    'Rp. ${NumberFormat('#,##0', 'id_ID').format(totalIncome)}',
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pengeluaran', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  Text(
                                    'Rp. ${NumberFormat('#,##0', 'id_ID').format(totalExpense)}',
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Saldo', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  Text(
                                    'Rp. ${NumberFormat('#,##0', 'id_ID').format(balance)}',
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Daftar Tahun
                    Flexible(
                      child: ListView.builder(
                        itemCount: _transactions.isEmpty ? 0 : calculateYearlyTotals().keys.length,
                        itemBuilder: (context, index) {
                          final years = calculateYearlyTotals().keys.toList();
                          final year = years[index];
                          final data = calculateYearlyTotals()[year]!;
                          final income = data['income']!;
                          final expense = data['expense']!;
                          final balance = data['balance']!;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: ListTile(
                              title: Text('$year', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Rp. ${NumberFormat('#,##0', 'id_ID').format(income)}',
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Rp. ${NumberFormat('#,##0', 'id_ID').format(expense)}',
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Rp. ${NumberFormat('#,##0', 'id_ID').format(balance)}',
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTx = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTransactionScreen()),
          );
          if (newTx != null) {
            setState(() {
              _transactions.add(newTx);
            });
            DatabaseService.saveTransactions(_transactions);
            Future.delayed(const Duration(milliseconds: 100), () {
              _loadTransactions();
            });
          }
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}