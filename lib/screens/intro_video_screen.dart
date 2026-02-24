import 'dart:async';
import 'package:flutter/material.dart';

class IntroVideoScreen extends StatefulWidget {
  final VoidCallback onIntroFinished;
  const IntroVideoScreen({super.key, required this.onIntroFinished});

  @override
  State<IntroVideoScreen> createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> slideAnim;
  late Animation<double> scaleAnim;
  late Animation<double> fadeText;

  int dotCount = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    slideAnim = Tween<double>(
      begin: 1.2,
      end: 0.0,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    scaleAnim = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    fadeText = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Loading dots
    Timer.periodic(const Duration(milliseconds: 400), (timer) {
      setState(() {
        dotCount = (dotCount + 1) % 4;
      });
    });

    // End intro
    Future.delayed(const Duration(seconds: 4), () {
      widget.onIntroFinished();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // Wallet animation
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Positioned(
                bottom: h * 0.45 + (slideAnim.value * 120),
                left: 0,
                right: 0,
                child: Transform.scale(
                  scale: scaleAnim.value,
                  child: child,
                ),
              );
            },
            child: Center(
              child: Image.asset(
                'assets/images/wallet.png',
                width: 130,
              ),
            ),
          ),

          // Text & loading
          Positioned(
            bottom: h * 0.28,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: fadeText,
              child: Column(
                children: [
                  RichText(
                    text: const TextSpan(
                      text: 'Dompet',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(
                          text: 'Ku',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'loading${'.' * dotCount}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
