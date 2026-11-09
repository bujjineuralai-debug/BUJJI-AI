import 'package:flutter/material.dart';

class ToolsHome extends StatelessWidget {
  final VoidCallback onOpenCalculator;
  final VoidCallback onOpenCurrencyConverter;
  final VoidCallback onOpenWhatIsThis;
  final VoidCallback onOpenRoomDesigner;
  final VoidCallback onOpenBrainChallenge;
  final VoidCallback onOpenHandwriting;
  final VoidCallback onOpenVoiceStudio;

  const ToolsHome({
    super.key,
    required this.onOpenCalculator,
    required this.onOpenCurrencyConverter,
    required this.onOpenWhatIsThis,
    required this.onOpenRoomDesigner,
    required this.onOpenBrainChallenge,
    required this.onOpenHandwriting,
    required this.onOpenVoiceStudio,
  });

  static const Color background = Color(0xFF071426);
  static const Color card = Color(0xFF10243D);
  static const Color cyan = Color(0xFF00D9FF);
  static const Color gold = Color(0xFFFFC857);

  Widget _toolCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    Color accent = cyan,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withOpacity(0.38)),
            boxShadow: [
              BoxShadow(color: accent.withOpacity(0.06), blurRadius: 14),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 31),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(
                      color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.bold,
                    )),
                    const SizedBox(height: 5),
                    Text(description, style: const TextStyle(
                      color: Colors.white60, fontSize: 12, height: 1.4,
                    )),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: gold, size: 18),
            ],
          ),
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
            const Text('BUJJI AI Tools', style: TextStyle(
              color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 7),
            const Text('Choose a tool to get started.', style: TextStyle(
              color: Colors.white60, fontSize: 14,
            )),
            const SizedBox(height: 22),
            _toolCard(title: 'Smart Calculator',
              description: 'Basic, GST, EMI and Calculation History',
              icon: Icons.calculate_rounded, onTap: onOpenCalculator),
            _toolCard(title: 'Currency Converter',
              description: 'Convert world currencies with saved offline rates',
              icon: Icons.currency_exchange_rounded, onTap: onOpenCurrencyConverter,
              accent: gold),
            _toolCard(title: 'What Is This?',
              description: 'Identify objects from a photo with AI',
              icon: Icons.center_focus_strong_rounded, onTap: onOpenWhatIsThis),
            _toolCard(title: 'Room Designer',
              description: 'Get room layout, colour and decor suggestions',
              icon: Icons.chair_alt_rounded, onTap: onOpenRoomDesigner,
              accent: gold),
            _toolCard(title: 'Brain Challenge',
              description: 'Play quizzes, logic questions and puzzles',
              icon: Icons.psychology_alt_rounded, onTap: onOpenBrainChallenge),
            _toolCard(title: 'Handwriting to Text',
              description: 'Scan a page and extract readable text',
              icon: Icons.document_scanner_rounded, onTap: onOpenHandwriting,
              accent: gold),
            _toolCard(title: 'Voice Studio',
              description: 'Record, save and play back your voice',
              icon: Icons.graphic_eq_rounded, onTap: onOpenVoiceStudio),
          ],
        ),
      ),
    );
  }
}
