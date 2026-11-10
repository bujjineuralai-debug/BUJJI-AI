import 'package:flutter/material.dart';

class BujjiMenuHome extends StatelessWidget {
  final VoidCallback onOpenAbout;
  final VoidCallback onOpenFeedback;

  const BujjiMenuHome({
    super.key,
    required this.onOpenAbout,
    required this.onOpenFeedback,
  });

  static const Color background = Color(0xFF071426);
  static const Color card = Color(0xFF10243D);
  static const Color cyan = Color(0xFF20D9E8);
  static const Color gold = Color(0xFFFFC857);

  static const List<_MenuItem> items = [
    _MenuItem(Icons.account_circle_rounded, 'My Account',
        'Profile, name and BUJJI Account'),
    _MenuItem(Icons.settings_rounded, 'App Settings',
        'Language, theme and notifications'),
    _MenuItem(Icons.mic_rounded, 'Voice & Translation',
        'Voice conversations and live translation'),
    _MenuItem(Icons.menu_book_rounded, 'My Learning',
        'Saved conversations, vocabulary and progress'),
    _MenuItem(Icons.shield_rounded, 'Privacy & Security',
        'Your data, permissions and account controls'),
    _MenuItem(Icons.workspace_premium_rounded, 'BUJJI Premium',
        'Plans, subscription and benefits'),
    _MenuItem(Icons.support_agent_rounded, 'Help & Support',
        'FAQs and contact support'),
    _MenuItem(Icons.share_rounded, 'Share BUJJI AI',
        'Share the app with friends'),
    _MenuItem(Icons.feedback_rounded, 'Feedback & Suggestions',
        'Send ideas and report a problem'),
    _MenuItem(Icons.info_outline_rounded, 'About BUJJI AI',
        'App version and developer information'),
  ];

  void _showComingSoon(BuildContext context, _MenuItem item) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF10243D),
        icon: Icon(item.icon, color: cyan, size: 32),
        title: Text(item.title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'ఈ Menu option జోడించబడింది. దీని వివరాలు, పనితీరును మనం ఒక్కొక్కటిగా చర్చించి అమలు చేద్దాం.',
          style: TextStyle(color: Color(0xFFCBD8E8), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK', style: TextStyle(color: cyan)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 20, 18, 6),
            child: Text(
              'BUJJI AI Menu',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Text(
              'Everything you need, in one place.',
              style: TextStyle(color: Color(0xFF9AACC1), fontSize: 13),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.12,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                final accent = index == 5 ? gold : cyan;
                return Material(
                  color: card,
                  borderRadius: BorderRadius.circular(17),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(17),
                    onTap: () {
                      if (item.title == 'About BUJJI AI') {
                        onOpenAbout();
                      } else if (item.title == 'Feedback & Suggestions') {
                        onOpenFeedback();
                      } else {
                        _showComingSoon(context, item);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: accent.withOpacity(0.30)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.icon, color: accent, size: 29),
                          const SizedBox(height: 11),
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xFF9AACC1),
                                fontSize: 10,
                                height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String description;

  const _MenuItem(this.icon, this.title, this.description);
}
