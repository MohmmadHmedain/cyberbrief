// lib/screens/home_screen.dart
import 'package:flutter/material.dart';

import '../app_strings.dart'; // ✅ ترجمة النصوص

import 'cyber_news_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import 'chat_ai_screen.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const route = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _pages = const [
    CyberNewsScreen(),
    ReportScreen(),
    ChatAiScreen(),
    ChatBotScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final t = S.of; // ✅ اختصار للترجمة

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF050B18),
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (i) => setState(() => _currentIndex = i),

        // ❗️ما نقدر نخليها const لأن النص صار ديناميكي حسب اللغة
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_rounded),
            label: t(context, 'nav_dashboard'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search_rounded),
            label: t(context, 'nav_scan'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.smart_toy_rounded),
            label: t(context, 'nav_ai_chat'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_rounded),
            label: t(context, 'nav_report'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_rounded),
            label: t(context, 'nav_settings'),
          ),
        ],
      ),
    );
  }
}