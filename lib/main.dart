
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

class BujjiHomeScreen extends StatefulWidget {
  const BujjiHomeScreen({super.key});

  @override
  State<BujjiHomeScreen> createState() => _BujjiHomeScreenState();
}

class _BujjiHomeScreenState extends State<BujjiHomeScreen> {
  int selectedIndex = 0;

  final TextEditingController messageController =
      TextEditingController();

  final Color cyan = const Color(0xFF20D9E8);
  final Color gold = const Color(0xFFFFC857);
  final Color navy = const Color(0xFF071629);

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
    super.dispose();
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
        const Expanded(child: SizedBox()),
      ],
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Voice input will be added later.',
                  ),
                ),
              );
            },
            icon: Icon(
              Icons.mic_none_rounded,
              color: cyan,
            ),
          ),
          Expanded(
            child: TextField(
              controller: messageController,
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Chat will be enabled after UI approval.',
                  ),
                ),
              );
            },
            icon: Icon(
              Icons.send_rounded,
              color: gold,
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
                      duration: const Duration(
                        milliseconds: 200,
                      ),
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
        if ((points[i] - points[j]).distance <
            size.width * 0.20) {
          canvas.drawLine(
            points[i],
            points[j],
            linePaint,
          );
        }
      }
    }

    for (final point in points) {
      final glowPaint = Paint()
        ..color = const Color(0xFF00DDF5).withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          7,
        );

      canvas.drawCircle(point, 5, glowPaint);

      final dotPaint = Paint()
        ..color = const Color(0xFF13CBEA).withValues(alpha: 0.70);

      canvas.drawCircle(point, 1.7, dotPaint);
    }

    final cyanWave = Path()
      ..moveTo(0, size.height * 0.82)
      ..cubicTo(
        size.width * 0.20,
        size.height * 0.77,
        size.width * 0.32,
        size.height * 0.91,
        size.width * 0.53,
        size.height * 0.87,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.83,
        size.width * 0.82,
        size.height * 0.76,
        size.width,
        size.height * 0.81,
      );

    final cyanPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF00BFEA),
          Color(0xFF20E6D0),
          Color(0xFFFFC857),
        ],
      ).createShader(rect);

    canvas.drawPath(cyanWave, cyanPaint);

    final secondWave = Path()
      ..moveTo(0, size.height * 0.85)
      ..cubicTo(
        size.width * 0.23,
        size.height * 0.80,
        size.width * 0.36,
        size.height * 0.94,
        size.width * 0.57,
        size.height * 0.90,
      )
      ..cubicTo(
        size.width * 0.76,
        size.height * 0.85,
        size.width * 0.87,
        size.height * 0.80,
        size.width,
        size.height * 0.85,
      );

    final secondPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFF00CFE8).withValues(alpha: 0.45);

    canvas.drawPath(secondWave, secondPaint);

    final goldGlow = Paint()
      ..color = const Color(0xFFFFC857).withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        35,
      );

    canvas.drawCircle(
      Offset(size.width * 0.90, size.height * 0.84),
      65,
      goldGlow,
    );
  }

  @override
  bool shouldRepaint(
    covariant BujjiBackgroundPainter oldDelegate,
  ) {
    return false;
  }
}
