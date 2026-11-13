import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/bujji_api_client.dart';

class WritingAssistantScreen extends StatefulWidget {
  const WritingAssistantScreen({super.key});

  @override
  State<WritingAssistantScreen> createState() =>
      _WritingAssistantScreenState();
}

class _WritingAssistantScreenState extends State<WritingAssistantScreen> {
  final BujjiApiClient apiClient = const BujjiApiClient();
  static const List<String> writingTypes = [
    'Job Application Letter',
    'Leave Letter',
    'Complaint Letter',
    'Request Letter',
    'Permission Letter',
    'Resignation Letter',
    'Thank You Letter',
    'Official Letter',
    'Professional Email',
    'Job Application Email',
    'Follow-up Email',
    'Meeting Request Email',
    'Business Proposal Email',
    'Apology Email',
    'Invitation Email',
    'Customer Support Email',
    'Custom Letter or Email',
  ];

  final TextEditingController detailsController =
      TextEditingController();
  final TextEditingController outputController =
      TextEditingController();

  String selectedType = writingTypes.first;
  String selectedLanguage = 'English';
  String selectedTone = 'Professional';
  String selectedLength = 'Medium';
  bool isGenerating = false;
  String lastPrompt = '';

  final Color cyan = const Color(0xFF25B8FF);

  @override
  void dispose() {
    detailsController.dispose();
    outputController.dispose();
    super.dispose();
  }

  Future<void> generateWriting({bool regenerate = false}) async {
    if (isGenerating) return;
    final details = detailsController.text.trim();
    if (details.isEmpty) {
      showNotice('Please enter the details first.');
      return;
    }
    if (details.length > 3000) {
      showNotice('Details are too long. Please keep them under 3000 characters.');
      return;
    }

    final prompt = '''
Create a complete $selectedType.
Language: $selectedLanguage.
Tone: $selectedTone.
Length: $selectedLength.
User details and instructions:
$details

Write a polished, ready-to-use draft. Do not invent personal facts, names,
dates, addresses, or contact details. Use clear placeholders such as
[Your Name] wherever information is missing. Return only the draft.
''';

    setState(() {
      isGenerating = true;
      lastPrompt = prompt;
      if (!regenerate) outputController.clear();
    });

    try {
      final result = await apiClient.sendChat(message: prompt);

      if (!mounted) return;
      setState(() {
        outputController.text = result;
      });
    } catch (error) {
      if (mounted) showNotice('Generation failed: $error');
    } finally {
      if (mounted) setState(() => isGenerating = false);
    }
  }

  void showNotice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF10243B),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: cyan, fontSize: 12)),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF0B1B2D),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0D1D30),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cyan.withOpacity(0.35)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cyan.withOpacity(0.35)),
            ),
          ),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF06101E),
        foregroundColor: Colors.white,
        title: const Text('Letters & Emails'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choose what you want to write',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          buildDropdown(
            label: 'LETTER / EMAIL TYPE',
            value: selectedType,
            items: writingTypes,
            onChanged: (value) {
              if (value != null) setState(() => selectedType = value);
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: buildDropdown(
                  label: 'LANGUAGE',
                  value: selectedLanguage,
                  items: const ['Telugu', 'English', 'Hindi'],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedLanguage = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildDropdown(
                  label: 'TONE',
                  value: selectedTone,
                  items: const ['Formal', 'Friendly', 'Professional'],
                  onChanged: (value) {
                    if (value != null) setState(() => selectedTone = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          buildDropdown(
            label: 'LENGTH',
            value: selectedLength,
            items: const ['Short', 'Medium', 'Detailed'],
            onChanged: (value) {
              if (value != null) setState(() => selectedLength = value);
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'What should the letter or email say?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: detailsController,
            maxLines: 5,
            minLines: 3,
            maxLength: 3000,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText:
                  'Enter purpose, names, dates and other details...',
              hintStyle: const TextStyle(color: Color(0xFF9AACC1)),
              filled: true,
              fillColor: const Color(0xFF0D1D30),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: cyan.withOpacity(0.35)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: cyan.withOpacity(0.35)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 49,
            child: ElevatedButton.icon(
              onPressed: isGenerating ? null : () => generateWriting(),
              icon: isGenerating
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(isGenerating ? 'Generating...' : 'Generate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cyan,
                foregroundColor: const Color(0xFF03111F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
          if (outputController.text.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Your Draft (you can edit it below)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 9),
            TextField(
              controller: outputController,
              maxLines: null,
              minLines: 8,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0D1D30),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: cyan.withOpacity(0.35)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: cyan.withOpacity(0.35)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: outputController.text),
                      );
                      if (mounted) showNotice('Draft copied.');
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isGenerating
                        ? null
                        : () => generateWriting(regenerate: true),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Regenerate'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}


class FeatureAssistantScreen extends StatefulWidget {
  final String title;
  final String typeLabel;
  final List<String> types;
  final String detailsHint;
  final bool languageMode;

  const FeatureAssistantScreen({
    super.key,
    required this.title,
    required this.typeLabel,
    required this.types,
    required this.detailsHint,
    this.languageMode = false,
  });

  @override
  State<FeatureAssistantScreen> createState() => _FeatureAssistantScreenState();
}

class _FeatureAssistantScreenState extends State<FeatureAssistantScreen> {
  final BujjiApiClient apiClient = const BujjiApiClient();
  final TextEditingController detailsController = TextEditingController();
  final TextEditingController outputController = TextEditingController();
  static const List<String> languages = ['Telugu', 'English', 'Hindi'];
  String selectedType = '';
  String selectedLanguage = 'English';
  String sourceLanguage = 'Auto Detect';
  String selectedTone = 'Friendly';
  String selectedLength = 'Medium';
  bool isGenerating = false;
  final Color cyan = const Color(0xFF25B8FF);

  @override
  void initState() {
    super.initState();
    selectedType = widget.types.first;
  }

  @override
  void dispose() {
    detailsController.dispose();
    outputController.dispose();
    super.dispose();
  }

  void showNotice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Color(0xFF10243B), fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: cyan, fontSize: 12)),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF0B1B2D),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0D1D30),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cyan.withOpacity(0.35))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cyan.withOpacity(0.35))),
          ),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Future<void> generateContent({bool regenerate = false}) async {
    if (isGenerating) return;
    final details = detailsController.text.trim();
    if (details.isEmpty) {
      showNotice('Please enter some details first.');
      return;
    }
    if (details.length > 3000) {
      showNotice('Please keep your details under 3000 characters.');
      return;
    }

    final languageInstructions = widget.languageMode
        ? 'Task: $selectedType. Source language: $sourceLanguage. Target language: $selectedLanguage. If this is a chat task, reply naturally in the target language.'
        : 'Content type: $selectedType. Language: $selectedLanguage. Tone: $selectedTone. Length: $selectedLength.';
    final prompt = '''
You are BUJJI AI's ${widget.title} assistant.
$languageInstructions
User input and instructions:
$details

Create a useful, polished result that follows the selected task.
Do not invent personal facts or claim details the user did not provide.
Return only the result, without explaining these instructions.
''';

    setState(() {
      isGenerating = true;
      if (!regenerate) outputController.clear();
    });
    try {
      final result = await apiClient.sendChat(message: prompt);
      if (!mounted) return;
      setState(() => outputController.text = result);
    } catch (error) {
      if (mounted) showNotice('Generation failed: $error');
    } finally {
      if (mounted) setState(() => isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020A14),
      appBar: AppBar(backgroundColor: const Color(0xFF06101E), foregroundColor: Colors.white, title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.languageMode ? 'Choose your language task' : 'Create with BUJJI AI', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          buildDropdown(
            label: widget.typeLabel,
            value: selectedType,
            items: widget.types,
            onChanged: (value) { if (value != null) setState(() => selectedType = value); },
          ),
          const SizedBox(height: 14),
          if (widget.languageMode) ...[
            buildDropdown(
              label: 'SOURCE LANGUAGE',
              value: sourceLanguage,
              items: const ['Auto Detect', 'Telugu', 'English', 'Hindi'],
              onChanged: (value) { if (value != null) setState(() => sourceLanguage = value); },
            ),
            const SizedBox(height: 14),
            buildDropdown(
              label: 'TARGET / REPLY LANGUAGE',
              value: selectedLanguage,
              items: languages,
              onChanged: (value) { if (value != null) setState(() => selectedLanguage = value); },
            ),
          ] else ...[
            Row(
              children: [
                Expanded(child: buildDropdown(
                  label: 'LANGUAGE',
                  value: selectedLanguage,
                  items: languages,
                  onChanged: (value) { if (value != null) setState(() => selectedLanguage = value); },
                )),
                const SizedBox(width: 10),
                Expanded(child: buildDropdown(
                  label: 'TONE',
                  value: selectedTone,
                  items: const ['Friendly', 'Formal', 'Professional', 'Funny', 'Emotional'],
                  onChanged: (value) { if (value != null) setState(() => selectedTone = value); },
                )),
              ],
            ),
            const SizedBox(height: 14),
            buildDropdown(
              label: 'LENGTH',
              value: selectedLength,
              items: const ['Short', 'Medium', 'Detailed'],
              onChanged: (value) { if (value != null) setState(() => selectedLength = value); },
            ),
          ],
          const SizedBox(height: 16),
          const Text('YOUR DETAILS / TEXT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: detailsController,
            maxLines: 5,
            minLines: 3,
            maxLength: 3000,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.detailsHint,
              hintStyle: const TextStyle(color: Color(0xFF9AACC1)),
              filled: true,
              fillColor: const Color(0xFF0D1D30),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cyan.withOpacity(0.35))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cyan.withOpacity(0.35))),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 49,
            child: ElevatedButton.icon(
              onPressed: isGenerating ? null : () => generateContent(),
              icon: isGenerating ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome_rounded),
              label: Text(isGenerating ? 'Generating...' : 'Generate'),
              style: ElevatedButton.styleFrom(backgroundColor: cyan, foregroundColor: const Color(0xFF03111F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
            ),
          ),
          if (outputController.text.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('BUJJI AI RESULT (EDITABLE)', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 9),
            TextField(
              controller: outputController,
              maxLines: null,
              minLines: 8,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0D1D30),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cyan.withOpacity(0.35))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cyan.withOpacity(0.35))),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: outputController.text));
                    if (mounted) showNotice('Copied successfully.');
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy'),
                )),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(
                  onPressed: isGenerating ? null : () => generateContent(regenerate: true),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Regenerate'),
                )),
              ],
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

