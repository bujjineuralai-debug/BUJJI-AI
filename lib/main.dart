
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

void main() {
  runApp(const BujjiAIApp());
}

class BujjiAIApp extends StatelessWidget {
  const BujjiAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BUJJI AI',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF030D1B),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const BujjiHomeScreen(),
    );
  }
}

class ChatMessage {
  final String role;
  final String content;

  const ChatMessage({
    required this.role,
    required this.content,
  });

  Map<String, String> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }
}

class BujjiHomeScreen extends StatefulWidget {
  const BujjiHomeScreen({super.key});

  @override
  State<BujjiHomeScreen> createState() => _BujjiHomeScreenState();
}

class _BujjiHomeScreenState extends State<BujjiHomeScreen> {
  static const String apiUrl =
      'https://bujji-ai-api.bujji-neural-ai.workers.dev/chat';

  int selectedIndex = 0;
  bool isLoading = false;

  final TextEditingController messageController =
      TextEditingController();

  final ScrollController chatScrollController =
      ScrollController();

  final List<ChatMessage> messages = [];

  final Color cyan = const Color(0xFF20D9E8);
  final Color gold = const Color(0xFFFFC857);

  final List<String> navigationItems = [
    'Home',
    'Tools',
    'History',
    'Favorites',
    'Explore',
  ];

  final List<IconData> navigationIcons = [
    Icons.home_rounded,
    Icons.grid_view_rounded,
    Icons.history_rounded,
    Icons.favorite_border_rounded,
    Icons.explore_outlined,
  ];

  @override
  void dispose() {
    messageController.dispose();
    chatScrollController.dispose();
    super.dispose();
  }

  // SEND MESSAGE TO CLOUDFLARE AI
  Future<void> sendMessage() async {
    if (isLoading) return;

    final String message = messageController.text.trim();

    if (message.isEmpty) return;

    if (message.length > 4000) {
      showMessage('Message is too long.');
      return;
    }

    // Keep previous conversation for AI context.
    final List<Map<String, String>> history =
        messages.map((item) => item.toJson()).toList();

    setState(() {
      messages.add(
        ChatMessage(
          role: 'user',
          content: message,
        ),
      );

      isLoading = true;
    });

    messageController.clear();
    scrollToBottom();

    final HttpClient client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);

    try {
      final Uri uri = Uri.parse(apiUrl);

      final HttpClientRequest request =
          await client.postUrl(uri).timeout(
        const Duration(seconds: 30),
      );

      request.headers.contentType = ContentType.json;
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/json',
      );

      request.add(
        utf8.encode(
          jsonEncode({
            'message': message,
            'history': history,
          }),
        ),
      );

      final HttpClientResponse response =
          await request.close().timeout(
        const Duration(seconds: 60),
      );

      final String responseBody =
          await utf8.decoder.bind(response).join().timeout(
        const Duration(seconds: 30),
      );

      final dynamic decoded = jsonDecode(responseBody);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid server response.');
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded['success'] != true) {
        throw Exception(
          decoded['error']?.toString() ??
              'Unable to get AI response.',
        );
      }

      final String reply =
          decoded['reply']?.toString() ?? '';

      if (reply.trim().isEmpty) {
        throw Exception('AI returned an empty response.');
      }

      if (!mounted) return;

      setState(() {
        messages.add(
          ChatMessage(
            role: 'assistant',
            content: reply.trim(),
          ),
        );
      });

      scrollToBottom();
    } catch (error) {
      if (!mounted) return;

      showMessage(
        'BUJJI AI connection failed. Please try again.',
      );

      debugPrint('BUJJI AI Error: $error');
    } finally {
      client.close(force: true);

      if (mounted) {
        setState(() {
          isLoading = false;
        });

        scrollToBottom();
      }
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !chatScrollController.hasClients) {
        return;
      }

      chatScrollController.animateTo(
        chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF142B42),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030D1B),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: BujjiBackgroundPainter(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: selectedIndex == 0
                      ? _buildHomeContent()
                      : _buildPlaceholder(),
                ),
                _buildComposer(),
                _buildBottomNavigation(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: const Color(0xDD071426),
        border: Border(
          bottom: BorderSide(
            color: cyan.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: cyan.withValues(alpha: 0.65),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: cyan.withValues(alpha: 0.20),
                  blurRadius: 13,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/bujji_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.blur_circular_rounded,
                    color: cyan,
                    size: 36,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BUJJI AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4,
                  ),
                ),
                Text(
                  'Your Personal AI Assistant',
                  style: TextStyle(
                    color: cyan,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: cyan.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: cyan.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.hub_rounded,
                  size: 16,
                  color: cyan,
                ),
                const SizedBox(width: 5),
                Text(
                  'Hybrid Mode',
                  style: TextStyle(
                    color: cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 22, 16, 12),
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xE8153652),
                Color(0xE8091B30),
                Color(0xE817293F),
              ],
            ),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: cyan.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: cyan.withValues(alpha: 0.12),
                blurRadius: 22,
              ),
              BoxShadow(
                color: gold.withValues(alpha: 0.04),
                blurRadius: 15,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.waving_hand_rounded,
                    color: gold,
                    size: 25,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Hello, Boss!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                'I am BUJJI AI.',
                style: TextStyle(
                  color: cyan,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Your personal assistant is ready. '
                'How can I help you today?',
                style: TextStyle(
                  color: Color(0xFFCBD8E8),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        // CHAT AREA
        Expanded(
          child: messages.isEmpty
              ? const SizedBox()
              : ListView.builder(
                  controller: chatScrollController,
                  padding: const EdgeInsets.fromLTRB(
                    14, 5, 14, 12,
                  ),
                  itemCount: messages.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return _buildTypingIndicator();
                    }

                    return _buildMessageBubble(messages[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bool isUser = message.role == 'user';

    return Align(
      alignment:
          isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF123A50)
              : const Color(0xFF0C2035),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: isUser
                ? gold.withValues(alpha: 0.45)
                : cyan.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          message.content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0C2035),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cyan.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 17,
              width: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cyan,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'BUJJI AI is thinking...',
              style: TextStyle(
                color: Color(0xFFCBD8E8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            navigationIcons[selectedIndex],
            size: 42,
            color: cyan,
          ),
          const SizedBox(height: 12),
          Text(
            navigationItems[selectedIndex],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'This section will be built after Home UI approval.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9AACC1),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      margin: const EdgeInsets.fromLTRB(13, 8, 13, 12),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xEE071629),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: cyan.withValues(alpha: 0.50),
        ),
        boxShadow: [
          BoxShadow(
            color: cyan.withValues(alpha: 0.08),
            blurRadius: 15,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              showMessage('Voice input will be added later.');
            },
            icon: Icon(
              Icons.mic_none_rounded,
              color: cyan,
            ),
          ),
          Expanded(
            child: TextField(
              controller: messageController,
              enabled: !isLoading,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => sendMessage(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              decoration: const InputDecoration(
                hintText: 'Message BUJJI AI...',
                hintStyle: TextStyle(
                  color: Color(0xFF9BAABD),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            onPressed: isLoading ? null : sendMessage,
            icon: Icon(
              Icons.send_rounded,
              color: isLoading ? Colors.white38 : gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.only(
        top: 10,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xEE071426),
        border: Border(
          top: BorderSide(
            color: cyan.withValues(alpha: 0.30),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          navigationItems.length,
          (index) {
            final bool isSelected = selectedIndex == index;

            return Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      navigationIcons[index],
                      size: 23,
                      color: isSelected
                          ? cyan
                          : Colors.white54,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      navigationItems[index],
                      style: TextStyle(
                        color: isSelected
                            ? cyan
                            : Colors.white54,
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 3,
                      width: isSelected ? 25 : 0,
                      decoration: BoxDecoration(
                        color: cyan,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// PREMIUM FUTURISTIC BACKGROUND
class BujjiBackgroundPainter extends CustomPainter {
  const BujjiBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF061426),
          Color(0xFF020B18),
          Color(0xFF06172A),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, backgroundPaint);

    final points = <Offset>[];

    for (int i = 0; i < 58; i++) {
      final x = ((i * 137.5) % 1000) / 1000 * size.width;
      final y = ((i * 83.7 + 25) % 1000) / 1000 * size.height;
      points.add(Offset(x, y));
    }

    final linePaint = Paint()
      ..color = const Color(0xFF00CFE8).withValues(alpha: 0.17)
      ..strokeWidth = 0.7;

    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final distance = (points[i]
