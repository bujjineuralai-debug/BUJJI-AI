import 'package:flutter/material.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  static const Color background = Color(0xFF020A14);
  static const Color panel = Color(0xFF0B1B2D);
  static const Color cyan = Color(0xFF25B8FF);
  static const Color muted = Color(0xFF9AACC1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF06101E),
        foregroundColor: Colors.white,
        title: const Text('Privacy & Security'),
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
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF12304A), Color(0xFF0D1D30), Color(0xFF10243B)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cyan.withOpacity(0.45)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_rounded, color: cyan, size: 38),
                  SizedBox(height: 12),
                  Text(
                    'Your privacy matters',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Understand what this version of BUJJI AI accesses and how to protect your information.',
                    style: TextStyle(color: muted, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            _section(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'AI Chat & Data',
              children: const [
                _InfoText(
                  'When you use online AI features, your message and the conversation context needed for the reply are sent to the BUJJI AI service over an encrypted HTTPS connection.',
                ),
                _InfoText(
                  'In this app version, chat messages are kept in the active screen session and are not saved as a local chat history by the app.',
                ),
                _InfoText(
                  'This screen does not confirm server-side retention practices. Avoid entering passwords, banking details, government ID numbers or other highly sensitive information into AI chats.',
                ),
              ],
            ),
            _section(
              icon: Icons.mic_none_rounded,
              title: 'Microphone Permission',
              children: const [
                _InfoText(
                  'BUJJI AI uses microphone access when you start voice recognition, so your speech can be converted into text.',
                ),
                _InfoText(
                  'Speech recognition is provided through your device speech service. Audio processing may depend on your Android settings and the speech service you use.',
                ),
                _InfoText(
                  'You can review or revoke microphone access in Android Settings → Apps → BUJJI AI → Permissions.',
                ),
              ],
            ),
            _section(
              icon: Icons.phonelink_lock_rounded,
              title: 'Device & App Security',
              children: const [
                _InfoText(
                  'Keep Android and BUJJI AI updated. Use a secure screen lock and do not share your unlocked phone with others.',
                ),
                _InfoText(
                  'Install BUJJI AI only from a source you trust. Review app permissions in Android Settings and allow only what you need.',
                ),
                _InfoText(
                  'The app requires Internet access for online AI features. Network requests use HTTPS; clear-text HTTP traffic is disabled in the Android app configuration.',
                ),
              ],
            ),
            _section(
              icon: Icons.tune_rounded,
              title: 'Your Privacy Controls',
              children: const [
                _InfoText(
                  'To manage microphone access, open Android Settings → Apps → BUJJI AI → Permissions.',
                ),
                _InfoText(
                  'You can stop using voice recognition at any time by tapping the microphone control again or leaving the voice input flow.',
                ),
                _InfoText(
                  'This version does not yet provide in-app account, data export, or server-data deletion controls. We will add such controls only when the related services are implemented.',
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cyan.withOpacity(0.25)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: cyan, size: 21),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Privacy information applies to the current app version and may change as BUJJI AI features evolve. Please review this page after app updates.',
                      style: TextStyle(color: muted, fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _section({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 13),
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ...children,
        ],
      ),
    );
  }
}

class _InfoText extends StatelessWidget {
  final String text;

  const _InfoText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, color: PrivacySecurityScreen.cyan, size: 6),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
