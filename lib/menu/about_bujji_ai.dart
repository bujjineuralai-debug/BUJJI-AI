import 'package:flutter/material.dart';
import 'ai_diagnostics_screen.dart';

class AboutBujjiAIScreen extends StatelessWidget {
  const AboutBujjiAIScreen({super.key});

  static const Color background = Color(0xFF020A14);
  static const Color panel = Color(0xFF0D1D30);
  static const Color cyan = Color(0xFF25B8FF);
  static const Color gold = Color(0xFFFFC857);
  static const Color muted = Color(0xFF9AACC1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF06101E),
        foregroundColor: Colors.white,
        title: const Text('About BUJJI AI'),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF061426), background, Color(0xFF06172A)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
          children: [
            _buildHero(),
            const SizedBox(height: 14),
            _section(
              icon: Icons.info_outline_rounded,
              title: 'About BUJJI AI',
              child: const Text(
                'BUJJI AI is your personal AI assistant, designed to help you ask questions, explore ideas, learn new things and get everyday tasks done in one place.',
                style: TextStyle(color: Colors.white, height: 1.55, fontSize: 13),
              ),
            ),
            _section(
              icon: Icons.flag_rounded,
              title: 'Our Vision & Mission',
              child: const Text(
                'Our vision is to make useful AI experiences accessible to everyone. Our mission is to make learning, creativity and everyday productivity simpler through friendly technology.',
                style: TextStyle(color: Colors.white, height: 1.55, fontSize: 13),
              ),
            ),
            _section(
              icon: Icons.auto_awesome_rounded,
              title: 'Explore BUJJI AI',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _FeatureChip(icon: Icons.chat_bubble_rounded, label: 'AI Chat'),
                  _FeatureChip(icon: Icons.grid_view_rounded, label: 'Smart Tools'),
                  _FeatureChip(icon: Icons.history_rounded, label: 'History'),
                  _FeatureChip(icon: Icons.favorite_rounded, label: 'Favorites'),
                  _FeatureChip(icon: Icons.explore_rounded, label: 'Explore'),
                  _FeatureChip(icon: Icons.mic_rounded, label: 'Voice'),
                  _FeatureChip(icon: Icons.menu_book_rounded, label: 'Learning'),
                ],
              ),
            ),
            _section(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Why BUJJI AI?',
              child: const Column(
                children: [
                  _Bullet(text: 'Simple and friendly experience'),
                  _Bullet(text: 'Useful AI tools in one app'),
                  _Bullet(text: 'Support for learning and creativity'),
                  _Bullet(text: 'Continuous improvements'),
                ],
              ),
            ),
            _section(
              icon: Icons.shield_outlined,
              title: 'Privacy & Security',
              child: const Text(
                'Your trust matters to us. We aim to handle information responsibly and provide clear controls. Please review the app permissions and privacy information before sharing sensitive details.',
                style: TextStyle(color: Colors.white, height: 1.55, fontSize: 13),
              ),
            ),
            _section(
              icon: Icons.code_rounded,
              title: 'Developer & Credits',
              child: const Text(
                'Developed by the BUJJI AI Team. BUJJI AI is built with Flutter and other open-source technologies. We appreciate the developers and communities behind those projects.',
                style: TextStyle(color: Colors.white, height: 1.55, fontSize: 13),
              ),
            ),
            _section(
              icon: Icons.mail_outline_rounded,
              title: 'Connect With Us',
              child: const Text(
                'Have an idea, found a problem or want to share your experience? Open Feedback & Suggestions from the Menu. Official contact links will be added here when they are available.',
                style: TextStyle(color: Colors.white, height: 1.55, fontSize: 13),
              ),
            ),
            _section(
              icon: Icons.monitor_heart_outlined,
              title: 'AI Diagnostics',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'View recent API health, response times and Trace IDs. Diagnostic records are stored locally and exclude prompts, tokens and images.',
                    style: TextStyle(color: Colors.white, height: 1.5, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AiDiagnosticsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text('Open Diagnostics Dashboard'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cyan,
                        side: BorderSide(color: cyan.withOpacity(0.5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _section(
              icon: Icons.system_update_alt_rounded,
              title: "What's New",
              child: const Text(
                'We are continuously working to improve BUJJI AI and add useful features. Check future app updates for the latest changes.',
                style: TextStyle(color: Colors.white, height: 1.55, fontSize: 13),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF12304A), Color(0xFF0D1D30), Color(0xFF12304A)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cyan.withOpacity(0.45)),
                boxShadow: [
                  BoxShadow(color: cyan.withOpacity(0.10), blurRadius: 20),
                ],
              ),
              child: const Column(
                children: [
                  Text('BUJJI AI', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  SizedBox(height: 7),
                  Text('Learn More. Do More. Grow More.', textAlign: TextAlign.center, style: TextStyle(color: gold, fontSize: 15, fontWeight: FontWeight.bold)),
                  SizedBox(height: 7),
                  Text('Your Personal AI Assistant', style: TextStyle(color: cyan, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text('BUJJI AI  •  Version 1.0.0 (Build 1)', style: TextStyle(color: muted, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF12304A), Color(0xFF0D1D30), Color(0xFF10243B)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cyan.withOpacity(0.55)),
        boxShadow: [
          BoxShadow(color: cyan.withOpacity(0.12), blurRadius: 20),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cyan.withOpacity(0.65), width: 1.4),
              boxShadow: [BoxShadow(color: cyan.withOpacity(0.16), blurRadius: 14)],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/bujji_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.smart_toy_rounded, color: cyan, size: 42),
              ),
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BUJJI AI', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                SizedBox(height: 5),
                Text('Your Personal AI Assistant', style: TextStyle(color: cyan, fontSize: 12)),
                SizedBox(height: 8),
                Text('Version 1.0.0  •  Build 1', style: TextStyle(color: muted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required IconData icon, required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: panel.withOpacity(0.94),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: cyan.withOpacity(0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cyan, size: 21),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 11),
          child,
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF12334D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF25B8FF).withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF25B8FF), size: 15),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF25B8FF), size: 17),
          const SizedBox(width: 9),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13))),
        ],
      ),
    );
  }
}
