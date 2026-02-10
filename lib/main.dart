import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // WAJIB
import 'screens/intro_video_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale Indonesia
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DompetKu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const IntroScreenWrapper(),
    );
  }
}

class IntroScreenWrapper extends StatefulWidget {
  const IntroScreenWrapper({super.key});

  @override
  State<IntroScreenWrapper> createState() => _IntroScreenWrapperState();
}

class _IntroScreenWrapperState extends State<IntroScreenWrapper> {
  bool _introPlayed = false;

  @override
  Widget build(BuildContext context) {
    return _introPlayed
        ? const HomeScreen()
        : IntroVideoScreen(
            onIntroFinished: () {
              setState(() {
                _introPlayed = true;
              });
            },
          );
  }
}
