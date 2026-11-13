import 'dart:async';
import 'package:flutter/material.dart';
import '../features/chat/presentation/bujji_home_screen.dart';

class BujjiStartupScreen extends StatefulWidget {
  const BujjiStartupScreen({super.key});

  @override
  State<BujjiStartupScreen> createState() => _BujjiStartupScreenState();
}

class _BujjiStartupScreenState extends State<BujjiStartupScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const BujjiHomeScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF25B8FF);

    return Scaffold(
      backgroundColor: const Color(0xFF020A14),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF061426),
              Color(0xFF020A14),
              Color(0xFF06172A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 154,
                height: 154,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cyan.withOpacity(0.65),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cyan.withOpacity(0.20),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/bujji_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'BUJJI AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your Personal AI Assistant',
                style: TextStyle(
                  color: cyan,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 34),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(cyan),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

