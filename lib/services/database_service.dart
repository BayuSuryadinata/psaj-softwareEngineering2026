import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import 'dart:convert';

class DatabaseService {
  static const String keyTransactions = 'transactions';

  static Future<void> saveTransactions(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = transactions.map((tx) => tx.toJson()).toList();
    await prefs.setStringList(keyTransactions, jsonList.map((e) => jsonEncode(e)).toList());
  }

  static Future<List<Transaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStringList = prefs.getStringList(keyTransactions) ?? [];
    return jsonStringList
        .map((jsonString) => Transaction.fromJson(jsonDecode(jsonString)))
        .toList();
  }

  static Future<void> clearTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyTransactions);
  }
}