import 'package:flutter/material.dart';

class ToolsHome extends StatelessWidget {
  final VoidCallback onOpenCalculator;
  final VoidCallback onOpenCurrencyConverter;

  const ToolsHome({
    super.key,
    required this.onOpenCalculator,
    required this.onOpenCurrencyConverter,
  });

  static const Color background = Color(0xFF071426);
  static const Color card = Color(0xFF10243D);
  static const Color cyan = Color(0xFF00D9FF);
  static const Color gold = Color(0xFFFFC857);

  Widget _toolCard({
    required VoidCallback onTap,
    required IconData icon,
    required String title,
    required String description,
    required Color accent,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withOpacity(0.45)),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.08),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 58,
              width: 58,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent, size: 34),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: gold,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      width: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BUJJI AI Tools',
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Choose a tool to get started.',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _toolCard(
              onTap: onOpenCalculator,
              icon: Icons.calculate_rounded,
              title: 'Smart Calculator',
              description: 'Basic, GST, EMI and Calculation History',
              accent: cyan,
            ),
            const SizedBox(height: 14),
            _toolCard(
              onTap: onOpenCurrencyConverter,
              icon: Icons.currency_exchange_rounded,
              title: 'Currency Converter',
              description: 'Convert currencies with updated exchange rates',
              accent: gold,
            ),
          ],
        ),
      ),
    );
  }
}
