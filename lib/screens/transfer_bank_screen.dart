import 'package:flutter/material.dart';
import 'transfer_detail_screen.dart';

class TransferBankScreen extends StatelessWidget {
  const TransferBankScreen({super.key});

  final List<String> banks = const [
    "Bank Syariah Indonesia",
    "Bank Mandiri",
    "Bank Rakyat Indonesia",
    "Bank Central Asia",
    "Bank Negara Indonesia",
    "Bank Permata",
    "Bank Aceh",
    "SeaBank Indonesia",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Transfer 💸"),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F2A5F),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: banks.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              leading: Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  ),
                ),
                child: const Icon(Icons.account_balance,
                    color: Colors.white),
              ),
              title: Text(
                banks[index],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TransferDetailScreen(selectedBank: banks[index]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}