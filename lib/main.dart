
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'tools/smart_calculator.dart';
import 'tools/currency_converter.dart';
import 'tools/tools_home.dart';
import 'tools/feature_tools.dart';
import 'menu/menu_home.dart';
import 'menu/about_bujji_ai.dart';
import 'menu/feedback_suggestions.dart';
import 'menu/help_support.dart';
import 'menu/privacy_security.dart';
import 'menu/menu_features.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.android,
  );
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
        scaffoldBackgroundColor: const Color(0xFF020A14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF25B8FF),
          secondary: Color(0xFFFFC857),
          surface: Color(0xFF0B1B2D),
          error: Color(0xFFFF6B6B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF06101E),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF0B1B2D),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0x3325B8FF)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0D1D30),
          labelStyle: const TextStyle(color: Color(0xFF25B8FF)),
          hintStyle: const TextStyle(color: Color(0xFF91A7BC)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0x5525B8FF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFFFC857), width: 1.4),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25B8FF),
            foregroundColor: const Color(0xFF020A14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const BujjiStartupScreen(),
    );
  }
}

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
  State<BujjiHomeScreen> createState() =>
      _BujjiHomeScreenState();
}

enum BujjiMode { smartAuto, onlineAI, offline }

class _BujjiHomeScreenState extends State<BujjiHomeScreen> {
  static const String apiUrl =
      'https://bujji-ai-api.bujji-neural-ai.workers.dev/chat';

  int selectedIndex = 0;
  bool isLoading = false;
  BujjiMode selectedMode = BujjiMode.smartAuto;

  String get modeLabel {
    switch (selectedMode) {
      case BujjiMode.smartAuto:
        return 'Smart Auto';
      case BujjiMode.onlineAI:
        return 'Online AI';
      case BujjiMode.offline:
        return 'Offline Mode';
    }
  }

  String getOfflineReply(String message) {
    final String text = message.toLowerCase().trim();
    if (text == 'hi' || text == 'hello' || text == 'hey' ||
        text.contains('నమస్కారం') || text.contains('హాయ్')) {
      return 'హాయ్! నేను BUJJI AI. ప్రస్తుతం పరిమిత Offline Mode లో ఉన్నాను. Internet అందుబాటులోకి వచ్చిన తర్వాత Smart Auto ఎంచుకుంటే పూర్తి Online AI సహాయం పొందవచ్చు.';
    }
    if (text.contains('help') || text.contains('ఏం చేయగలవు') ||
        text.contains('సహాయం')) {
      return 'Offline Mode లో ప్రస్తుతం ప్రాథమిక స్థానిక సహాయం మాత్రమే అందుబాటులో ఉంది. పూర్తి ప్రశ్నలకు, వివరణలకు మరియు AI సమాధానాలకు Internet అవసరం.';
    }
    return 'ప్రస్తుతం Internet కనెక్షన్ లేదు. Offline Mode లో పరిమిత స్థానిక సహాయం మాత్రమే అందుబాటులో ఉంది. పూర్తి AI సమాధానాల కోసం Internet వచ్చినప్పుడు Smart Auto లేదా Online AI ఎంచుకోండి.';
  }

  void addAssistantReply(String reply) {
    if (!mounted) return;
    setState(() {
      messages.add(ChatMessage(role: 'assistant', content: reply));
    });
    scrollToBottom();
  }

  Future<void> chooseMode() async {
    final BujjiMode? mode = await showModalBottomSheet<BujjiMode>(
      context: context,
      backgroundColor: const Color(0xFF0D1D30),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose BUJJI Mode', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _modeOption(sheetContext, BujjiMode.smartAuto, 'Smart Auto', 'Internet ఉంటే Online AI; లేకపోతే పరిమిత Offline సహాయం', Icons.auto_awesome_rounded),
              _modeOption(sheetContext, BujjiMode.onlineAI, 'Online AI', 'పూర్తి AI సమాధానాల కోసం Internet అవసరం', Icons.cloud_rounded),
              _modeOption(sheetContext, BujjiMode.offline, 'Offline Mode', 'Internet లేనప్పుడు పరిమిత స్థానిక సహాయం', Icons.cloud_off_rounded),
            ],
          ),
        ),
      ),
    );
    if (mode == null || !mounted) return;
    setState(() => selectedMode = mode);
    if (mode == BujjiMode.offline) {
      showMessage('Offline Mode ఎంపికైంది. పరిమిత స్థానిక సహాయం మాత్రమే అందుబాటులో ఉంటుంది.');
    }
  }

  Widget _modeOption(BuildContext sheetContext, BujjiMode mode, String title, String subtitle, IconData icon) {
    final bool selected = selectedMode == mode;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: selected ? cyan : Colors.white70),
      title: Text(title, style: TextStyle(color: selected ? cyan : Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF9AACC1), fontSize: 12)),
      trailing: selected ? Icon(Icons.check_circle_rounded, color: cyan) : null,
      onTap: () => Navigator.pop(sheetContext, mode),
    );
  }

  bool speechInitialized = false;
  bool isListening = false;

  String voiceBaseText = '';

  final SpeechToText speech = SpeechToText();

  final TextEditingController messageController =
      TextEditingController();

  final ScrollController chatScrollController =
      ScrollController();

  final List<ChatMessage> messages = [];

  final Color cyan = const Color(0xFF25B8FF);
  final Color gold = const Color(0xFFFFC857);

  final List<String> navigationItems = [
    'Home',
    'Tools',
    'History',
    'Favorites',
    'Explore',
    'Menu',
  ];

  final List<IconData> navigationIcons = [
    Icons.home_rounded,
    Icons.grid_view_rounded,
    Icons.history_rounded,
    Icons.favorite_border_rounded,
    Icons.explore_outlined,
    Icons.menu_rounded,
  ];

  @override
  void dispose() {
    speech.cancel();
    messageController.dispose();
    chatScrollController.dispose();
    super.dispose();
  }

  Future<void> toggleVoiceRecognition() async {
    if (isLoading) return;

    if (isListening || speech.isListening) {
      await stopVoiceRecognition();
      return;
    }

    try {
      if (!speechInitialized) {
        speechInitialized = await speech.initialize(
          onStatus: (status) {
            if (!mounted) return;

            setState(() {
              isListening = status == 'listening';
            });
          },
          onError: (error) {
            if (!mounted) return;

            setState(() {
              isListening = false;
            });

            showMessage(
              'Voice recognition error: ${error.errorMsg}',
            );
          },
        );
      }

      if (!speechInitialized) {
        showMessage(
          'Speech recognition is unavailable. '
          'Please check your microphone and speech settings.',
        );
        return;
      }

      voiceBaseText = messageController.text.trim();

      final locale = await speech.systemLocale();

      if (!mounted) return;

      await speech.listen(
        onResult: (result) {
          if (!mounted) return;

          final String recognized =
              result.recognizedWords.trim();

          if (recognized.isEmpty) return;

          final String updatedText = voiceBaseText.isEmpty
              ? recognized
              : '$voiceBaseText $recognized';

          setState(() {
            messageController.value = TextEditingValue(
              text: updatedText,
              selection: TextSelection.collapsed(
                offset: updatedText.length,
              ),
            );
          });
        },
        localeId: locale?.localeId,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 8),
        partialResults: true,
        listenMode: ListenMode.dictation,
        cancelOnError: false,
      );

      if (mounted) {
        setState(() {
          isListening = speech.isListening;
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isListening = false;
      });

      showMessage(
        'Unable to start voice recognition: $error',
      );
    }
  }

  Future<void> stopVoiceRecognition() async {
    try {
      await speech.stop();
    } catch (error) {
      debugPrint('Speech stop error: $error');
    }

    if (mounted) {
      setState(() {
        isListening = false;
      });
    }
  }

  Future<void> sendMessage() async {
    if (isLoading) return;

    if (speech.isListening) {
      await stopVoiceRecognition();
    }

    final String message = messageController.text.trim();
    if (message.isEmpty) return;
    if (message.length > 4000) {
      showMessage('Message is too long.');
      return;
    }

    final List<Map<String, String>> history =
        messages.map((item) => item.toJson()).toList();

    setState(() {
      messages.add(ChatMessage(role: 'user', content: message));
      isLoading = true;
    });
    messageController.clear();
    scrollToBottom();

    if (selectedMode == BujjiMode.offline) {
      addAssistantReply(getOfflineReply(message));
      setState(() => isLoading = false);
      return;
    }

    final HttpClient client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);

    try {
      final Uri uri = Uri.parse(apiUrl);
      final HttpClientRequest request =
          await client.postUrl(uri).timeout(const Duration(seconds: 30));
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.add(utf8.encode(jsonEncode({
        'message': message,
        'history': history,
      })));

      final HttpClientResponse response =
          await request.close().timeout(const Duration(seconds: 60));
      final String responseBody =
          await utf8.decoder.bind(response).join().timeout(
                const Duration(seconds: 30),
              );

      dynamic decoded;
      try {
        decoded = jsonDecode(responseBody);
      } catch (_) {
        throw Exception(
          'HTTP ${response.statusCode}: Invalid JSON response.',
        );
      }

      if (decoded is! Map<String, dynamic>) {
        throw Exception('HTTP ${response.statusCode}: Invalid server response.');
      }
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded['success'] != true) {
        final String serverError = decoded['error']?.toString() ??
            decoded['message']?.toString() ?? 'Unknown server error';
        throw Exception('HTTP ${response.statusCode}: $serverError');
      }

      final String reply = decoded['reply']?.toString() ?? '';
      if (reply.trim().isEmpty) {
        throw Exception('AI returned an empty response.');
      }
      addAssistantReply(reply.trim());
    } on SocketException catch (error) {
      if (selectedMode == BujjiMode.smartAuto) {
        addAssistantReply(getOfflineReply(message));
      } else {
        showMessage('Internet connection unavailable: $error');
      }
    } on TimeoutException {
      if (selectedMode == BujjiMode.smartAuto) {
        addAssistantReply(getOfflineReply(message));
      } else {
        showMessage('Online AI timed out. Please try again.');
      }
    } on HttpException catch (error) {
      if (selectedMode == BujjiMode.smartAuto) {
        addAssistantReply(getOfflineReply(message));
      } else {
        showMessage('Online AI error: $error');
      }
    } catch (error) {
      if (!mounted) return;
      debugPrint('BUJJI AI Error: $error');
      final String errorDetails = error.toString();
      final String visibleError = errorDetails.length > 220
          ? '${errorDetails.substring(0, 220)}...'
          : errorDetails;
      showMessage('BUJJI AI error: $visibleError');
    } finally {
      client.close(force: true);
      if (mounted) {
        setState(() => isLoading = false);
        scrollToBottom();
      }
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !chatScrollController.hasClients) {
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
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFF10243B),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020A14),
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
                      : selectedIndex == 1
                          ? ToolsHome(
                              onOpenCurrencyConverter: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CurrencyConverter()));
                              },
                              onOpenCalculator: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SmartCalculator()));
                              },
                              onOpenWhatIsThis: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const WhatIsThisScreen()));
                              },
                              onOpenRoomDesigner: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RoomDesignerScreen()));
                              },
                              onOpenBrainChallenge: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const BrainChallengeScreen()));
                              },
                              onOpenHandwriting: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HandwritingToTextScreen()));
                              },
                              onOpenVoiceStudio: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const VoiceStudioScreen()));
                              },
                            )
                          : selectedIndex == 5
                              ? BujjiMenuHome(
                                  onOpenAbout: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const AboutBujjiAIScreen(),
                                      ),
                                    );
                                  },
                                  onOpenFeedback: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const FeedbackSuggestionsScreen(),
                                      ),
                                    );
                                  },
                                  onOpenHelp: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const HelpSupportScreen(),
                                      ),
                                    );
                                  },
                                  onOpenPrivacy: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const PrivacySecurityScreen(),
                                      ),
                                    );
                                  },
                                  onOpenAccount: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyAccountScreen())),
                                  onOpenSettings: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppSettingsScreen())),
                                  onOpenVoice: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VoiceTranslationScreen())),
                                  onOpenLearning: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyLearningScreen())),
                                  onOpenPremium: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BujjiPremiumScreen())),
                                  onOpenShare: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShareBujjiScreen())),
                                )
                              : _buildSectionContent(),
                ),
                if (selectedIndex == 0) _buildComposer(),
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
            color: cyan.withOpacity(0.35),
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
                color: cyan.withOpacity(0.65),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: cyan.withOpacity(0.20),
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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
          InkWell(
            onTap: chooseMode,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: cyan.withOpacity(0.10),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: cyan.withOpacity(0.45)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selectedMode == BujjiMode.offline
                        ? Icons.cloud_off_rounded
                        : selectedMode == BujjiMode.onlineAI
                            ? Icons.cloud_rounded
                            : Icons.hub_rounded,
                    size: 16,
                    color: cyan,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    modeLabel,
                    style: TextStyle(
                      color: cyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.arrow_drop_down_rounded, size: 16, color: cyan),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        if (messages.isEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(
              16, 22, 16, 12,
            ),
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
                color: cyan.withOpacity(0.55),
              ),
              boxShadow: [
                BoxShadow(
                  color: cyan.withOpacity(0.12),
                  blurRadius: 22,
                ),
                BoxShadow(
                  color: gold.withOpacity(0.04),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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
        Expanded(
          child: messages.isEmpty
              ? const SizedBox()
              : ListView.builder(
                  controller: chatScrollController,
                  padding: const EdgeInsets.fromLTRB(
                    14, 5, 14, 12,
                  ),
                  itemCount:
                      messages.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return _buildTypingIndicator();
                    }

                    return _buildMessageBubble(
                      messages[index],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bool isUser = message.role == 'user';

    return Align(
      alignment: isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF102B44)
              : const Color(0xFF0D1D30),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: isUser
                ? gold.withOpacity(0.45)
                : cyan.withOpacity(0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: message.content),
                  );
                  if (mounted) showMessage('Copied to clipboard.');
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: isUser ? gold : cyan,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Copy',
                        style: TextStyle(
                          color: isUser ? gold : cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
          color: const Color(0xFF0D1D30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cyan.withOpacity(0.35),
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

  Widget _buildSectionContent() {
    if (selectedIndex == 2) {
      return _buildEmptySection(
        icon: Icons.history_rounded,
        title: 'Chat History',
        description: 'Your previous conversations will appear here.',
        detail: 'Start a conversation from Home to begin using BUJJI AI.',
      );
    }

    if (selectedIndex == 3) {
      return _buildEmptySection(
        icon: Icons.favorite_rounded,
        title: 'Favorites',
        description: 'Your favorite conversations will appear here.',
        detail: 'You have not added any favorites yet.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
      children: [
        Text(
          'Explore BUJJI AI',
          style: TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Discover what you can do with your personal AI assistant.',
          style: TextStyle(
            color: Color(0xFF9AACC1),
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 22),
        _buildExploreCard(
          Icons.mail_outline_rounded,
          'Letters & Emails',
          'Write clear letters and professional emails.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const WritingAssistantScreen(),
              ),
            );
          },
        ),
        _buildExploreCard(
          Icons.chat_bubble_outline_rounded,
          'WhatsApp Messages',
          'Create friendly, thoughtful WhatsApp messages.',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const FeatureAssistantScreen(
              title: 'WhatsApp Messages',
              typeLabel: 'MESSAGE TYPE',
              types: ['Birthday Wishes', 'Congratulations', 'Thank You Message', 'Apology Message', 'Invitation Message', 'Good Morning / Good Night', 'Love & Friendship Message', 'Festival Wishes', 'Custom WhatsApp Message'],
              detailsHint: 'Who is the message for? What do you want to say?',
            ),
          )),
        ),
        _buildExploreCard(
          Icons.campaign_outlined,
          'Social Media Captions',
          'Create engaging captions for your social posts.',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const FeatureAssistantScreen(
              title: 'Social Media Captions',
              typeLabel: 'PLATFORM / CAPTION TYPE',
              types: ['Instagram Caption', 'Facebook Caption', 'YouTube Title & Description', 'Reel / Short Caption', 'Business Promotion', 'Product Promotion', 'Motivational Caption', 'Custom Social Media Caption'],
              detailsHint: 'Describe your photo, video, product or post. Add any keywords you want.',
            ),
          )),
        ),
        _buildExploreCard(
          Icons.auto_stories_rounded,
          'Stories & Poems',
          'Create imaginative stories and beautiful poems.',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const FeatureAssistantScreen(
              title: 'Stories & Poems',
              typeLabel: 'CONTENT TYPE',
              types: ['Short Story', 'Moral Story', 'Children Story', 'Horror Story', 'Love Story', 'Friendship Story', 'Love Poem', 'Friendship Poem', 'Motivational Poem', 'Custom Story or Poem'],
              detailsHint: 'Enter the topic, characters, theme, age group or any ideas you have.',
            ),
          )),
        ),
        _buildExploreCard(
          Icons.translate_rounded,
          'Multiple Languages',
          'Chat with BUJJI AI in Telugu, English and Hindi.',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const FeatureAssistantScreen(
              title: 'Multiple Languages',
              typeLabel: 'TASK',
              types: ['Translate Text', 'Chat with BUJJI', 'Explain in Simple Words', 'Rewrite in Another Language'],
              detailsHint: 'Type your message or text here.',
              languageMode: true,
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildEmptySection({
    required IconData icon,
    required String title,
    required String description,
    required String detail,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: cyan),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFCBD8E8),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF9AACC1),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreCard(
    IconData icon,
    String title,
    String description, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 13),
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: const Color(0xDD0B2035),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: cyan.withOpacity(0.30)),
        ),
        child: Row(
          children: [
            Icon(icon, color: cyan, size: 27),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFFCBD8E8),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios_rounded,
                  color: cyan, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        13, 8, 13, 12,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xEE071629),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: cyan.withOpacity(0.50),
        ),
        boxShadow: [
          BoxShadow(
            color: cyan.withOpacity(0.08),
            blurRadius: 15,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: isLoading
                ? null
                : toggleVoiceRecognition,
            icon: Icon(
              isListening
                  ? Icons.mic_rounded
                  : Icons.mic_none_rounded,
              color: isListening ? gold : cyan,
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
              color: isLoading
                  ? Colors.white38
                  : gold,
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
            color: cyan.withOpacity(0.30),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,
        children: List.generate(
          navigationItems.length,
          (index) {
            final bool isSelected =
                selectedIndex == index;

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
                      duration:
                          const Duration(milliseconds: 200),
                      height: 3,
                      width: isSelected ? 25 : 0,
                      decoration: BoxDecoration(
                        color: cyan,
                        borderRadius:
                            BorderRadius.circular(5),
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


class WritingAssistantScreen extends StatefulWidget {
  const WritingAssistantScreen({super.key});

  @override
  State<WritingAssistantScreen> createState() =>
      _WritingAssistantScreenState();
}

class _WritingAssistantScreenState extends State<WritingAssistantScreen> {
  static const String apiUrl =
      'https://bujji-ai-api.bujji-neural-ai.workers.dev/chat';

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

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);

    try {
      final request = await client
          .postUrl(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 30));
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.add(utf8.encode(jsonEncode({
        'message': prompt,
        'history': <Map<String, String>>[],
      })));

      final response = await request.close().timeout(
        const Duration(seconds: 60),
      );
      final body = await utf8.decoder.bind(response).join().timeout(
        const Duration(seconds: 30),
      );

      dynamic decoded;
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        throw Exception('Server returned an invalid response.');
      }

      if (decoded is! Map<String, dynamic> ||
          response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded['success'] != true) {
        throw Exception(
          decoded is Map
              ? (decoded['error']?.toString() ??
                  decoded['message']?.toString() ??
                  'Unable to generate the draft.')
              : 'Unable to generate the draft.',
        );
      }

      final result = decoded['reply']?.toString().trim() ?? '';
      if (result.isEmpty) throw Exception('BUJJI AI returned an empty draft.');

      if (!mounted) return;
      setState(() {
        outputController.text = result;
      });
    } catch (error) {
      if (mounted) showNotice('Generation failed: $error');
    } finally {
      client.close(force: true);
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
  static const String apiUrl = 'https://bujji-ai-api.bujji-neural-ai.workers.dev/chat';
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
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client.postUrl(Uri.parse(apiUrl)).timeout(const Duration(seconds: 30));
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.add(utf8.encode(jsonEncode({'message': prompt, 'history': <Map<String, String>>[]})));
      final response = await request.close().timeout(const Duration(seconds: 60));
      final body = await utf8.decoder.bind(response).join().timeout(const Duration(seconds: 30));
      dynamic decoded;
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        throw Exception('Server returned an invalid response.');
      }
      if (decoded is! Map<String, dynamic> || response.statusCode < 200 || response.statusCode >= 300 || decoded['success'] != true) {
        throw Exception(decoded is Map ? (decoded['error']?.toString() ?? decoded['message']?.toString() ?? 'Unable to generate content.') : 'Unable to generate content.');
      }
      final result = decoded['reply']?.toString().trim() ?? '';
      if (result.isEmpty) throw Exception('BUJJI AI returned an empty result.');
      if (!mounted) return;
      setState(() => outputController.text = result);
    } catch (error) {
      if (mounted) showNotice('Generation failed: $error');
    } finally {
      client.close(force: true);
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
      final x =
          ((i * 137.5) % 1000) / 1000 * size.width;

      final y =
          ((i * 83.7 + 25) % 1000) / 1000 * size.height;

      points.add(Offset(x, y));
    }

    final blueLinePaint = Paint()
      ..color = const Color(0xFF25B8FF).withOpacity(0.22)
      ..strokeWidth = 0.85;

    final goldLinePaint = Paint()
      ..color = const Color(0xFFFFC857).withOpacity(0.24)
      ..strokeWidth = 0.8;

    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final distance = (points[i] - points[j]).distance;
        if (distance < 145) {
          canvas.drawLine(
            points[i],
            points[j],
            ((i + j) % 5 == 0) ? goldLinePaint : blueLinePaint,
          );
        }
      }
    }

    final blueGlow = Paint()
      ..color = const Color(0xFF25B8FF).withOpacity(0.13)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final goldGlow = Paint()
      ..color = const Color(0xFFFFC857).withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final blueDot = Paint()..color = const Color(0xFF25B8FF);
    final goldDot = Paint()..color = const Color(0xFFFFC857);

    for (int i = 0; i < points.length; i++) {
      final isGold = i % 5 == 0;
      final point = points[i];
      canvas.drawCircle(point, 4.2, isGold ? goldGlow : blueGlow);
      canvas.drawCircle(point, 1.55, isGold ? goldDot : blueDot);
    }
  }

  @override
  bool shouldRepaint(
    covariant BujjiBackgroundPainter oldDelegate,
  ) {
    return false;
  }
}
