
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
        scaffoldBackgroundColor: const Color(0xFF070D19),
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
  final Color navy = const Color(0xFF0D1729);

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
      backgroundColor: const Color(0xFF070D19),
      body: SafeArea(
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
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1424),
        border: Border(
          bottom: BorderSide(
            color: cyan.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 43,
            width: 43,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  cyan.withValues(alpha: 0.25),
                  gold.withValues(alpha: 0.15),
                ],
              ),
              border: Border.all(
                color: cyan.withValues(alpha: 0.7),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'B',
              style: TextStyle(
                color: gold,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
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
                    color: cyan.withValues(alpha: 0.8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: cyan.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: cyan.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.hub_rounded,
                  size: 15,
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
          margin: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF142943),
                Color(0xFF101B30),
                Color(0xFF172238),
              ],
            ),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: cyan.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: cyan.withValues(alpha: 0.05),
                blurRadius: 18,
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
                    size: 22,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Hello, Boss!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Text(
                'I am BUJJI AI.',
                style: TextStyle(
                  color: cyan,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Your personal assistant is ready. '
                'How can I help you today?',
                style: TextStyle(
                  color: Color(0xFFB9C7D9),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        // Keep the central area clean and empty.
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
            style: TextStyle(
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
              color: Color(0xFF8C9AAF),
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
        color: navy,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: cyan.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Voice input will be added later.'),
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
                  color: Color(0xFF8492A7),
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
        color: const Color(0xFF0B1424),
        border: Border(
          top: BorderSide(
            color: cyan.withValues(alpha: 0.16),
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
                      size: 22,
                      color: isSelected ? cyan : Colors.white54,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      navigationItems[index],
                      style: TextStyle(
                        color: isSelected ? cyan : Colors.white54,
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 5),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 3,
                      width: isSelected ? 23 : 0,
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
