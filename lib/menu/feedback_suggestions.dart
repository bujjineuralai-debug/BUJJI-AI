import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedbackSuggestionsScreen extends StatefulWidget {
  const FeedbackSuggestionsScreen({super.key});

  @override
  State<FeedbackSuggestionsScreen> createState() =>
      _FeedbackSuggestionsScreenState();
}

class _FeedbackSuggestionsScreenState
    extends State<FeedbackSuggestionsScreen> {
  static const Color background = Color(0xFF030D1B);
  static const Color panel = Color(0xFF10243D);
  static const Color cyan = Color(0xFF20D9E8);
  static const Color muted = Color(0xFF9AACC1);

  final TextEditingController messageController = TextEditingController();
  String selectedType = 'Suggestion';
  int rating = 5;
  bool isSaving = false;

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  void showNotice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF10243D),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF20D9E8), width: 0.8),
        ),
      ),
    );
  }

  Future<void> saveFeedback() async {
    final message = messageController.text.trim();
    if (message.isEmpty) {
      showNotice('Please write your feedback or suggestion first.');
      return;
    }
    if (message.length > 2000) {
      showNotice('Please keep your message under 2000 characters.');
      return;
    }

    setState(() => isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = prefs.getStringList('bujji_feedback_drafts') ?? [];
      entries.add(jsonEncode({
        'type': selectedType,
        'rating': rating,
        'message': message,
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'saved_locally',
      }));
      await prefs.setStringList('bujji_feedback_drafts', entries);
      if (!mounted) return;
      messageController.clear();
      setState(() => rating = 5);
      showNotice('Feedback saved on this device.');
    } catch (_) {
      if (mounted) showNotice('Could not save feedback. Please try again.');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF071426),
        foregroundColor: Colors.white,
        title: const Text('Feedback & Suggestions'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cyan.withOpacity(0.28)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.feedback_rounded, color: cyan, size: 34),
                SizedBox(height: 12),
                Text(
                  'Help us make BUJJI AI better',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Share an idea, tell us what you like, or report something that is not working.',
                  style: TextStyle(color: muted, height: 1.5, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('FEEDBACK TYPE',
              style: TextStyle(color: cyan, fontWeight: FontWeight.w600)),
          const SizedBox(height: 9),
          DropdownButtonFormField<String>(
            value: selectedType,
            dropdownColor: panel,
            style: const TextStyle(color: Colors.white),
            decoration: _decoration(),
            items: const [
              DropdownMenuItem(value: 'Suggestion', child: Text('Suggestion')),
              DropdownMenuItem(value: 'Bug Report', child: Text('Report a problem')),
              DropdownMenuItem(value: 'App Experience', child: Text('App experience')),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => selectedType = value);
            },
          ),
          const SizedBox(height: 20),
          const Text('RATE YOUR EXPERIENCE',
              style: TextStyle(color: cyan, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              final value = index + 1;
              return IconButton(
                onPressed: () => setState(() => rating = value),
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  value <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: const Color(0xFFFFC857),
                  size: 31,
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          const Text('YOUR MESSAGE',
              style: TextStyle(color: cyan, fontWeight: FontWeight.w600)),
          const SizedBox(height: 9),
          TextField(
            controller: messageController,
            minLines: 5,
            maxLines: 8,
            maxLength: 2000,
            style: const TextStyle(color: Colors.white, height: 1.5),
            decoration: _decoration(
              hint: 'Write your idea, suggestion or the problem you noticed...',
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : saveFeedback,
              icon: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(isSaving ? 'Saving...' : 'Save Feedback'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cyan,
                foregroundColor: const Color(0xFF03111F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFF0B2035),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Note: Feedback is currently saved only on this device. It is not sent to the BUJJI AI team yet. We will connect secure feedback delivery after setting up an official support channel.',
              style: TextStyle(color: muted, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: muted, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF0B2035),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: cyan.withOpacity(0.30)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: cyan.withOpacity(0.30)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: cyan),
      ),
    );
  }
}
