import 'package:flutter/material.dart';
import 'feedback_suggestions.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const Color background = Color(0xFF030D1B);
  static const Color panel = Color(0xFF10243D);
  static const Color cyan = Color(0xFF20D9E8);
  static const Color muted = Color(0xFF9AACC1);

  static const List<_HelpItem> faqs = [
    _HelpItem(
      'What is BUJJI AI?',
      'BUJJI AI is your personal AI assistant, with chat and useful tools in one app.',
      Icons.auto_awesome_rounded,
    ),
    _HelpItem(
      'Does BUJJI AI need an internet connection?',
      'Online AI features need an active internet connection. Some app screens may still be available offline.',
      Icons.wifi_rounded,
    ),
    _HelpItem(
      'How can I report a problem or share an idea?',
      'Open Menu → Feedback & Suggestions, choose a feedback type, add your message and save it.',
      Icons.feedback_rounded,
    ),
    _HelpItem(
      'Is my feedback sent to the BUJJI AI team?',
      'At present, feedback is saved only on your device. It is not automatically sent to the team.',
      Icons.save_rounded,
    ),
    _HelpItem(
      'Where can I find app information?',
      'Open Menu → About BUJJI AI to view the app overview, vision and available feature information.',
      Icons.info_outline_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF071426),
        foregroundColor: Colors.white,
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cyan.withOpacity(0.30)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.support_agent_rounded, color: cyan, size: 36),
                SizedBox(height: 12),
                Text(
                  'How can we help you?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Find quick answers to common questions about BUJJI AI.',
                  style: TextStyle(color: muted, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'FREQUENTLY ASKED QUESTIONS',
            style: TextStyle(color: cyan, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...faqs.map(
            (faq) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cyan.withOpacity(0.18)),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  splashColor: cyan.withOpacity(0.08),
                  highlightColor: cyan.withOpacity(0.05),
                ),
                child: ExpansionTile(
                  iconColor: cyan,
                  collapsedIconColor: muted,
                  leading: Icon(faq.icon, color: cyan),
                  title: Text(
                    faq.question,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        faq.answer,
                        style: const TextStyle(
                          color: muted,
                          fontSize: 13,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0B2035),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.headset_mic_rounded, color: cyan),
                    SizedBox(width: 9),
                    Text(
                      'Contact & Support',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 9),
                Text(
                  'Our official support contact channel will be added in a future update. Until then, you can save your feedback from the Feedback & Suggestions screen on this device.',
                  style: TextStyle(color: muted, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 49,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FeedbackSuggestionsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.feedback_rounded),
              label: const Text('Go to Feedback & Suggestions'),
              style: OutlinedButton.styleFrom(
                foregroundColor: cyan,
                side: const BorderSide(color: cyan),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpItem {
  final String question;
  final String answer;
  final IconData icon;

  const _HelpItem(this.question, this.answer, this.icon);
}
